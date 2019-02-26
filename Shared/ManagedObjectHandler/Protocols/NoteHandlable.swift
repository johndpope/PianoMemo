//
//  NoteHandlable.swift
//  Piano
//
//  Created by hoemoon on 30/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData

typealias ChangeCompletion = ((Bool) -> Void)?

protocol NoteHandlable: class {
    var context: NSManagedObjectContext { get }

    func create(content: String, tags: String, needUpload: Bool, completion: ((Note?) -> Void)?)
    func create(content: String, in folder: Folder, completion: ((Note?) -> Void)?)
    func update(origin: Note, content: String, needToSave: Bool, completion: ChangeCompletion)
    func addTag(tags: String, notes: [Note], completion: ChangeCompletion)
    func removeTag(tags: String, notes: [Note], completion: ChangeCompletion)
    func remove(notes: [Note], completion: ChangeCompletion)
    func restore(notes: [Note], completion: ChangeCompletion)
    func pinNote(notes: [Note], completion: ChangeCompletion)
    func unPinNote(notes: [Note], completion: ChangeCompletion)
    func lockNote(notes: [Note], completion: ChangeCompletion)
    func unlockNote(notes: [Note], completion: ChangeCompletion)
    func purge(notes: [Note], completion: ChangeCompletion)
    func merge(notes: [Note], completion: ChangeCompletion)

    func move(notes: [Note], to destination: Folder, completion: ChangeCompletion)
    func saveIfNeeded()
    func update(notes: [Note], expireDate: Date?, completion: ChangeCompletion)

//    func neutralize(notes: [Note], completion: ChangeCompletion)
}

extension NoteHandlable {
    /// 노트를 생성합니다.
    ///
    /// - Parameters:
    ///   - content: 노트의 컨텐츠
    ///   - tags: 노트에 대한 태그
    ///   - needUpload: 원격 저장소에 업로드가 필요한지 여부를 표시. 기본값은 true
    ///   - completion: 성공시 저장된 노트 객체를 받는 completion handler
    func create(content: String,
                tags: String,
                needUpload: Bool = true,
                completion: ((Note?) -> Void)? = nil) {

        context.perform {
            let note = Note.insert(into: self.context, content: content, tags: tags)
            if needUpload {
                note.markUploadReserved()
            }
            if self.saveOrRollback() {
                completion?(note)
                Analytics.logEvent(createNote: note, size: content.count)
            } else {
                completion?(nil)
            }
        }
    }

    /// 특정한 폴더 내에 노트를 생성합니다.
    ///
    /// - Parameters:
    ///   - content: 노트의 컨텐츠
    ///   - folder: 폴더 객체
    ///   - completion: 성공시 저장된 노트 객체를 받는 completion handler
    func create(content: String,
                in folder: Folder,
                completion: ((Note?) -> Void)?) {

        context.perform {
            let note = Note.insert(into: self.context, content: content)
            note.markUploadReserved()
            note.folder = folder
            folder.markUploadReserved()
            if self.saveOrRollback() {
                completion?(note)
                Analytics.logEvent(createNote: note, size: content.count)
            } else {
                completion?(nil)
            }
        }
    }

    /// 노트의 컨텐츠를 갱신합니다.
    ///
    /// - Parameters:
    ///   - origin: 노트 객체
    ///   - content: 새로운 노트 컨텐츠
    ///   - needToSave: 디스크에 저장해야 되는지를 표시
    ///   - completion: 성공 여부를 Bool 값으로 받는 completion handler
    func update(origin: Note, content: String, needToSave: Bool, completion: ChangeCompletion = nil) {
        guard content.count > 0 else { purge(notes: [origin], completion: completion); return }
        performSyncUpdates(
            notes: [origin],
            content: content,
            needToSave: needToSave,
            completion: completion
        )
        Analytics.logEvent(updateNote: origin)
    }

    /// 노트에 태그를 추가합니다.
    ///
    /// - Parameters:
    ///   - tags: 추가할 태그
    ///   - notes: 변경할 노트 목록
    ///   - completion: 성공 여부를 Bool 값으로 받는 completion handler
    func addTag(tags: String, notes: [Note], completion: ChangeCompletion = nil) {
        performSyncUpdates(
            notes: notes,
            newTags: tags,
            needUpdateDate: false,
            completion: completion
        )
        guard let origin = notes.first else { return }
        Analytics.logEvent(attachTagsTo: origin, tags: tags)
    }

    /// 노트에서 태그를 삭제합니다.
    ///
    /// - Parameters:
    ///   - tags: 삭제할 태그
    ///   - notes: 변경할 노트 목록
    ///   - completion: 성공 여부를 Bool 값으로 받는 completion handler
    func removeTag(tags: String, notes: [Note], completion: ChangeCompletion = nil) {
        performSyncUpdates(
            notes: notes,
            removeTags: tags,
            needUpdateDate: false,
            completion: completion
        )
    }

    /// 노트를 삭제합니다.
    ///
    /// - Parameters:
    ///   - notes: 삭제할 노트 목록
    ///   - completion: 성공 여부를 Bool 값으로 받는 completion handler
    func remove(notes: [Note], completion: ChangeCompletion = nil) {
        performSyncUpdates(notes: notes, isRemoved: true, needUpdateDate: false, completion: completion)
        guard let origin = notes.first else { return }
        Analytics.logEvent(deleteNote: origin)
    }

    /// 노트를 복구합니다. 휴지통에서 목록으로 이동시킵니다.
    ///
    /// - Parameters:
    ///   - notes: 복구할 노트 목록
    ///   - completion: 성공 여부를 Bool 값으로 받는 completion handler
    func restore(notes: [Note], completion: ChangeCompletion = nil) {
        performSyncUpdates(
            notes: notes,
            isRemoved: false,
            needUpdateDate: false,
            completion: completion
        )
    }

    /// 노트를 리스트 상단에 고정시킵니다.
    ///
    /// - Parameters:
    ///   - notes: 고정할 노트 목록
    ///   - completion: 성공 여부를 Bool 값으로 받는 completion handler
    func pinNote(notes: [Note], completion: ChangeCompletion = nil) {
        performSyncUpdates(
            notes: notes,
            isPinned: 1,
            needUpdateDate: false,
            completion: completion
        )
    }

    /// 노트 고정을 해제 합니다.
    ///
    /// - Parameters:
    ///   - notes: 고정 해제할 노트 목록
    ///   - completion: 성공 여부를 Bool 값으로 받는 completion handler
    func unPinNote(notes: [Note], completion: ChangeCompletion = nil) {
        performSyncUpdates(
            notes: notes,
            isPinned: 0,
            needUpdateDate: false,
            completion: completion
        )
    }

    /// 노트들을 잠금 상태로 변경합니다.
    ///
    /// - Parameters:
    ///   - notes: 변경할 노트 목록
    ///   - completion: 성공 여부를 Bool 값으로 받는 completion handler
    func lockNote(notes: [Note], completion: ChangeCompletion) {
        performSyncUpdates(
            notes: notes,
            isLocked: true,
            needUpdateDate: false,
            completion: completion
        )
    }

    /// 잠금 상태의 노트들을 잠금 해제 상태로 변경합니다.
    ///
    /// - Parameters:
    ///   - notes: 변경할 노트 목록
    ///   - completion: 성공 여부를 Bool 값으로 받는 completion handler
    func unlockNote(notes: [Note], completion: ChangeCompletion = nil) {
        performSyncUpdates(
            notes: notes,
            isLocked: false,
            needUpdateDate: false,
            completion: completion
        )
    }

    /// 노트를 로컬에서 완전히 삭제하도록 예약합니다.
    ///
    /// - Parameters:
    ///   - notes: 삭제할 노트 목록
    ///   - completion: 성공 여부를 Bool 값으로 받는 completion handler
    func purge(notes: [Note], completion: ChangeCompletion = nil) {
        performSyncUpdates(
            notes: notes,
            isPurged: true,
            needUpdateDate: false,
            completion: completion
        )
    }

    /// 노트를 병합합니다.
    ///
    /// - Parameters:
    ///   - notes: 병합할 노트 목록
    ///   - completion: 성공 여부를 Bool 값으로 받는 completion handler
    func merge(notes: [Note], completion: ChangeCompletion = nil) {
        guard notes.count > 0 else { return }
        var deletes = notes
        let origin = deletes.removeFirst()

        var content = origin.content ?? ""
        var tagSet = Set((origin.tags ?? "").splitedEmojis)

        deletes.forEach {
            let noteContent = $0.content ?? ""
            if noteContent.trimmingCharacters(in: .newlines).count != 0 {
                content.append("\n" + noteContent)
            }
            ($0.tags ?? "").splitedEmojis.forEach {
                tagSet.insert($0)
            }
        }

        performSyncUpdates(
            notes: [origin],
            content: content,
            tags: tagSet.joined(),
            completion: completion
        )
        Analytics.logEvent(mergeNote: notes)
        purge(notes: deletes)
    }

    /// 노트를 해당 폴더로 이동시킵니다.
    ///
    /// - Parameters:
    ///   - notes: 이동시킬 노트 목록
    ///   - destination: 폴더 객체
    ///   - completion: 성공 여부를 Bool 값으로 받는 completion handler
    func move(notes: [Note], to destination: Folder, completion: ChangeCompletion = nil) {
        context.perform { [weak self] in
            guard let self = self else { return }
            notes.forEach {
                $0.folder = destination
                $0.markUploadReserved()
            }
            completion?(self.context.saveOrRollback())
        }
    }

    func update(notes: [Note], expireDate: Date?, completion: ChangeCompletion = nil) {
        context.perform { [weak self] in
            guard let self = self else { return }
            notes.forEach {
                $0.expireDate = expireDate
            }
            completion?(self.context.saveOrRollback())
        }
    }

//    func neutralize(notes: [Note], completion: ChangeCompletion) {
//        performSyncUpdates(
//            notes: notes,
//            isRemoved: false,
//            isLocked: false,
//            isPinned: 0,
//            needUpdateDate: false,
//            completion: completion
//        )
//    }
}

extension NoteHandlable {
    /// 컨텍스트의 미결된 변경 사항을 디스크에 저장합니다.
    ///
    /// - Returns: 성공여부
    @discardableResult
    private func saveOrRollback() -> Bool {
        guard context.hasChanges else { return false }
        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            return false
        }
    }

    /// 노트를 동기 방식으로 갱신합니다.
    /// notehandler의 대부분의 메서드는 이 메서드를 호출하게 됩니다.
    private func performSyncUpdates(
        notes: [Note],
        content: String? = nil,
        isRemoved: Bool? = nil,
        isLocked: Bool? = nil,
        isPinned: Int? = nil,
        isPurged: Bool? = nil,
        tags: String? = nil,
        newTags: String? = nil,
        removeTags: String? = nil,
        changeTags: String? = nil,
        needUpdateDate: Bool = true,
        isShared: Bool? = nil,
        needToSave: Bool = true,
        completion: ChangeCompletion = nil) {

        context.performAndWait {
            do {
                for item in notes {
                    let note = try self.context
                        .existingObject(with: item.objectID) as? Note
                    switch note {
                    case .some(let note):
                        if let isRemoved = isRemoved {
                            note.isRemoved = isRemoved
                        }
                        if let content = content {
                            note.content = content
                        }
                        if let isLocked = isLocked {
                            note.isLocked = isLocked
                        }
                        if let isPinned = isPinned {
                            note.isPinned = Int64(isPinned)
                        }
                        if let newTags = newTags {
                            note.tags = "\(note.tags ?? "")\(newTags)"
                        }
                        if let removeTags = removeTags {
                            var old = (note.tags ?? "")
                            old.removeCharacters(strings: [removeTags])
                            note.tags = old
                        }
                        if let changeTags = changeTags {
                            note.tags = changeTags
                        }
                        if let isShared = isShared {
                            note.isShared = isShared
                        }
                        if needUpdateDate {
                            note.modifiedAt = Date()
                        }
                        if isPurged != nil {
                            note.markForRemoteDeletion()
                        } else {
                            note.markUploadReserved()
                        }

                    case .none:
                        break
                    }
                }
                DispatchQueue.main.async {
                    completion?(true)
                }
                if needToSave {
                    context.perform {
                        self.context.saveOrRollback()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion?(false)
                }
            }
        }
    }

    func saveIfNeeded() {
        context.saveOrRollback()
    }
}
