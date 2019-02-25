//
//  ElementChangeProcessor.swift
//  Piano
//
//  Created by hoemoon on 26/02/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import CoreData
import CloudKit

protocol ElementChangeProcessor: ChangeProcessor {
    associatedtype Element: NSManagedObject, Managed

    var retriedErrorCodes: [Int] { get set }
    var elementsInProgress: InProgressTracker<Element> { get }
    var predicateForLocallyTrackedElements: NSPredicate { get }

    func processChangedLocalElements(_ elements: [Element], in context: ChangeProcessorContext)

    func handleError(
        context: ChangeProcessorContext,
        uploads: [Element],
        removes: [Element],
        error: Error
    )
}

extension ElementChangeProcessor {
    /// changeProcessor가 원격 저장소에 요청면서 에러가 발생할 경우 이 메서드가 처리합니다.
    /// 각각의 에러코드에 따라 다른 종류의 에러 처리가 진행됩니다.
    /// 특정 에러 코드에 대한 에러 처리를 실패하게 되면, 다시 시도하지 않습니다.
    func handleError(
        context: ChangeProcessorContext,
        uploads: [Element],
        removes: [Element],
        error: Error) {

        func flush() { retriedErrorCodes.removeAll() }

        guard let ckError = error as? CKError, !retriedErrorCodes.contains(ckError.errorCode) else { return }
        retriedErrorCodes.append(ckError.errorCode)

        switch ckError.code {
        case .zoneNotFound:
            context.remote.createZone { [weak self] _ in
                guard let self = self else { return }
                self.retryRequest(context: context, uploads: uploads, removes: removes) { success in
                    if success { flush() }
                }
            }
        case .serverRecordChanged, .partialFailure:
            retryRequest(context: context, uploads: uploads, removes: removes, error: ckError) { success in
                if success { flush() }
            }
        case .serviceUnavailable, .requestRateLimited, .zoneBusy:
            if let number = ckError.userInfo[CKErrorRetryAfterKey] as? NSNumber {
                DispatchQueue.global().asyncAfter(deadline: .now() + Double(truncating: number)) {
                    context.perform { [weak self] in
                        guard let self = self else { return }
                        self.retryRequest(context: context, uploads: uploads, removes: removes) { success in
                            if success { flush() }
                        }
                    }
                }
            }
        case .networkFailure, .networkUnavailable, .serverResponseLost:
            retryRequest(context: context, uploads: uploads, removes: removes) { success in
                if success { flush() }
            }
        case .incompatibleVersion, .notAuthenticated, .quotaExceeded:
            notify(error: ckError)
        default:
            return
        }
    }

    /// 사용자에세 메세지로 알려줘야 할 에러를 처리합니다.
    private func notify(error: CKError) {
        func postNotification(message: String, error: CKError) {
            let key = "didNotifyError\(error.errorCode)"
            if !UserDefaults.standard.bool(forKey: key) {
                let dict = ["message": message]
                NotificationCenter.default.post(
                    name: .displayCKErrorMessage,
                    object: nil,
                    userInfo: dict
                )
                UserDefaults.standard.set(true, forKey: key)
            }
        }
        switch error.code {
        case .incompatibleVersion:
            postNotification(message: "Update your app.", error: error)
        case .notAuthenticated:
            postNotification(message: "Sign in to iCloud.", error: error)
        case .quotaExceeded:
            postNotification(message: "Your iCloud storage is full.", error: error)
        default:
            break
        }
    }

    /// 서버에 다시 요청합니다.
    private func retryRequest(
        context: ChangeProcessorContext,
        uploads: [Element],
        removes: [Element],
        error: CKError? = nil,
        completion: @escaping (Bool) -> Void) {

        if uploads.count > 0, var notes = uploads as? [Note] {
            if uploads.count == 1,
                let note = uploads.first as? Note,
                let error = error,
                error.code == .serverRecordChanged,
                let resolved = resolve(error: error) {
                context.context.performAndWait {
                    note.content = resolved[NoteField.content]
                    notes = [note]
                }
            }

            context.remote.upload(notes, savePolicy: .allKeys) { saved, _, error in
                context.perform {
                    if error != nil {
                        completion(false)
                    }
                    guard let saved = saved else { return }
                    for note in notes {
                        guard let record = saved.first(
                            where: { note.modifiedAt == ($0.modifiedAtLocally as Date?) }) else { continue }
                        note.recordID = record.recordID
                        note.recordArchive = record.archived
                        note.resolveUploadReserved()
                    }
                    context.delayedSaveOrRollback()
                    completion(true)
                }
            }
        }
        if removes.count > 0, let notes = uploads as? [Note] {
            context.remote.remove(notes, savePolicy: .allKeys) { _, ids, error in
                context.perform {
                    if error != nil {
                        completion(false)
                    }
                    guard let ids = ids else { return }
                    let deletedIDs = Set(ids)
                    let toBeDeleted = notes.filter { deletedIDs.contains($0.remoteID!) }
                    toBeDeleted.forEach { $0.markForLocalDeletion() }
                    context.delayedSaveOrRollback()
                    completion(true)
                }
            }
        }
    }

    /// 충돌이 발생한 경우 해결된 레코드를 반환합니다.
    private func resolve(error: CKError) -> CKRecord? {
        let records = error.getMergeRecords()
        if let ancestorRecord = records.0,
            let clientRecord = records.1,
            let serverRecord = records.2 {

            return Resolver.merge(
                ancestor: ancestorRecord,
                client: clientRecord,
                server: serverRecord
            )
        } else if let server = records.2, let client = records.1 {
            if let serverModifiedAt = server.modificationDate,
                let clientMotifiedAt = client.modificationDate,
                let clientContent = client[NoteField.content] as? String {

                if serverModifiedAt > clientMotifiedAt {
                    return server
                } else {
                    server[NoteField.content] = clientContent
                    return server
                }
            }
            return server
        } else {
            return nil
        }
    }
}

extension ElementChangeProcessor {
    /// `processChangedLocalObjects(_ objects: [NSManagedObject])`에서
    /// 전달받은 객체들을 중 해당 changeProcess에 해당하는 객체만 필터링 합니다.
    func processChangedLocalObjects(_ objects: [NSManagedObject], in context: ChangeProcessorContext) {
        let matching = objects.filter(entityAndPredicateForLocallyTrackedObjects(in: context)!)
        if let elements = matching as? [Element] {
            let newElements = elementsInProgress.objectsToProcess(from: elements)
            processChangedLocalElements(newElements, in: context)
        }
    }

    /// 해당 changeProcessor에 대한 entity정보와 predicate를 반환합니다.
    func entityAndPredicateForLocallyTrackedObjects(in context: ChangeProcessorContext) -> EntityAndPredicate<NSManagedObject>? {
        let predicate = predicateForLocallyTrackedElements
        return EntityAndPredicate(entity: Element.entity(), predicate: predicate)
    }

    func processChangedLocalElements(_ elements: [Element], in context: ChangeProcessorContext) {
        switch processorType {
        case .upload:
            upload(elements, in: context)
        case .remove:
            remove(elements, in: context)
        }
    }
}

extension ElementChangeProcessor {
    /// 실제로 업로드를 요청하고, 결과에 따라 로컬 데이터베이스를 갱신합니다.
    private func upload(_ elements: [Element], in context: ChangeProcessorContext) {
        guard elements.count > 0, let recordables = elements as? [CloudKitRecordable] else { return }
        #if DEBUG
        print("UUUUUUUUUUUU👍")
        #endif
        context.remote.upload(recordables, savePolicy: .ifServerRecordUnchanged) { saved, _, error in
            context.perform { [weak self] in
                guard let self = self else { return }
                if let error = error {
                    self.elementsInProgress.markObjectsAsComplete(elements)
                    self.handleError(
                        context: context,
                        uploads: elements,
                        removes: [],
                        error: error
                    )
                    return
                }

                guard let saved = saved else { return }
                for recodable in recordables {
                    if let record = saved.first(
                        where: { recodable.modifiedAt == ($0.modifiedAtLocally as Date?) }) {
                        recodable.recordID = record.recordID
                        recodable.recordArchive = record.archived
                        (recodable as? UploadReservable)?.resolveUploadReserved()
                    }
                }
                context.delayedSaveOrRollback()
                self.elementsInProgress.markObjectsAsComplete(elements)
            }
        }
    }

    /// 실제로 삭제를 요청하고, 결과에 따라 로컬 데이터베이스를 갱신합니다.
    private func remove(_ elements: [Element], in context: ChangeProcessorContext) {
        guard elements.count > 0 else { return }

        let allObjects = Set(elements)
        let localOnly = allObjects.filter { ($0 as? CloudKitRecordable)?.remoteID == nil }
        let objectsToDeleteRemotely = allObjects.subtracting(localOnly)

        deleteLocally(localOnly, context: context)
        deleteRemotely(objectsToDeleteRemotely, context: context)

    }

    /// 로컬에서 완전히 삭제하는 것을 예약합니다.
    fileprivate func deleteLocally(_ deletions: Set<Element>, context: ChangeProcessorContext) {
        context.perform {
            deletions.forEach { ($0 as? DelayedDeletable)?.markForLocalDeletion() }
        }
    }

    /// 원격 저장소에 요청합니다.
    fileprivate func deleteRemotely(_ deletions: Set<Element>, context: ChangeProcessorContext) {
        guard let recordables = Array(deletions) as? [CloudKitRecordable] else { return }
        context.remote.remove(recordables, savePolicy: .ifServerRecordUnchanged) { _, ids, error in
            context.perform { [weak self] in
                guard let self = self, error == nil else { return }
                if let error = error {
                    self.elementsInProgress.markObjectsAsComplete(Array(deletions))
                    self.handleError(
                        context: context,
                        uploads: [],
                        removes: Array(deletions),
                        error: error
                    )
                    return
                }
                guard let ids = ids else { return }
                let deletedIDs = Set(ids)
                let toBeDeleted = recordables.filter { deletedIDs.contains($0.remoteID!) }
                self.deleteLocally(Set(toBeDeleted as! [Element]), context: context)
                context.delayedSaveOrRollback()
                self.elementsInProgress.markObjectsAsComplete(Array(deletions))
            }
        }
    }
}
