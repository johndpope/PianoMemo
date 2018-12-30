//
//  ChangeProcessor.swift
//  Piano
//
//  Created by hoemoon on 24/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData
import CloudKit

protocol ChangeProcessor: class {
    func processChangedLocalObjects(_ objects: [NSManagedObject], in context: ChangeProcessorContext)
    func entityAndPredicateForLocallyTrackedObjects(in context: ChangeProcessorContext) -> EntityAndPredicate<NSManagedObject>?
}

protocol ChangeProcessorContext: class {
    var context: NSManagedObjectContext { get }
    var remote: RemoteProvider { get }
    func perform(_ block: @escaping () -> Void)
    func delayedSaveOrRollback()
}

protocol ElementChangeProcessor: ChangeProcessor {
    associatedtype Element: NSManagedObject, Managed

    var retryCount: Int { get set }
    var elementsInProgress: InProgressTracker<Element> { get }
    var predicateForLocallyTrackedElements: NSPredicate { get }

    func processChangedLocalElements(_ elements: [Element], in context: ChangeProcessorContext)
    func handleError(context: ChangeProcessorContext, elements: [Element], error: Error)
}

extension ElementChangeProcessor {
    func handleError(context: ChangeProcessorContext, elements: [Element], error: Error) {
        guard let ckError = error as? CKError, retryCount == 0 else { return }
        switch ckError.code {
        case .zoneNotFound:
            context.remote.createZone { [weak self] _ in
                guard let self = self else { return }
                self.processChangedLocalObjects(elements, in: context)
            }
        case .serverRecordChanged:
            forceUpload(context: context, elements: elements)
        case .partialFailure:
            forceUpload(context: context, elements: elements)
        default:
            return
        }
        retryCount += 1
    }

    private func forceUpload(context: ChangeProcessorContext, elements:[Element]) {
        // TODO: 지금은 걍 올리는 거임. 개선하기
        guard let notes = elements as? [Note] else { return }
        context.remote.upload(notes, savePolicy: .allKeys) { saved, _, _ in
            guard let saved = saved else { return }
            for note in notes {
                guard let record = saved.first(
                    where: { note.modifiedAt == $0.modifiedAtLocally }) else { continue }
                note.recordID = record.recordID
                note.recordArchive = record.archived
                note.resolveUploadReserved()
            }
            context.delayedSaveOrRollback()
        }
    }


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
                let clientContent = client[Field.content] as? String {

                if serverModifiedAt > clientMotifiedAt {
                    return server
                } else {
                    server[Field.content] = clientContent
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
    func processChangedLocalObjects(_ objects: [NSManagedObject], in context: ChangeProcessorContext) {
        let matching = objects.filter(entityAndPredicateForLocallyTrackedObjects(in: context)!)
        if let elements = matching as? [Element] {
            let newElements = elementsInProgress.objectsToProcess(from: elements)
            processChangedLocalElements(newElements, in: context)
        }
    }

    func entityAndPredicateForLocallyTrackedObjects(in context: ChangeProcessorContext) -> EntityAndPredicate<NSManagedObject>? {
        let predicate = predicateForLocallyTrackedElements
        return EntityAndPredicate(entity: Element.entity(), predicate: predicate)
    }
}