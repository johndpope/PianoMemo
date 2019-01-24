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
    func create(content: String, folder: Folder?, needUpload: Bool, completion: ((Note?) -> Void)?)
    func update(origin: Note, content: String, completion: ChangeCompletion)
    func addTag(tags: String, notes: [Note], completion: ChangeCompletion)
    func removeTag(tags: String, notes: [Note], completion: ChangeCompletion)
    func updateTag(tags: String, note: Note, completion: ChangeCompletion)
    func remove(notes: [Note], completion: ChangeCompletion)
    func restore(notes: [Note], completion: ChangeCompletion)
    func pinNote(notes: [Note], completion: ChangeCompletion)
    func unPinNote(notes: [Note], completion: ChangeCompletion)
    func lockNote(notes: [Note], completion: ChangeCompletion)
    func unlockNote(notes: [Note], completion: ChangeCompletion)
    func purge(notes: [Note], completion: ChangeCompletion)
    func merge(notes: [Note], completion: ChangeCompletion)

    func move(notes: [Note], to destination: Folder, completion: ChangeCompletion)
    func syncUpdateContent(note: Note, content: String)
    func saveIfNeeded()
}

class NoteHandler: NSObject, NoteHandlable {
    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }
}

extension NoteHandlable {
    func create(
        content: String,
        tags: String,
        needUpload: Bool = true,
        completion: ((Note?) -> Void)? = nil) {

        context.perform {
            let note = Note.insert(into: self.context, content: content, tags: tags, needUpload: needUpload)
            if self.saveOrRollback() {
                completion?(note)
                Analytics.logEvent(createNote: note, size: content.count)
            } else {
                completion?(nil)
            }
        }
    }

    func create(
        content: String,
        folder: Folder?,
        needUpload: Bool = true,
        completion: ((Note?) -> Void)?) {

        context.perform {
            let note = Note.insert(into: self.context, content: content, needUpload: needUpload)
            if folder != nil {
                note.folder = folder
            }
            if self.saveOrRollback() {
                completion?(note)
                Analytics.logEvent(createNote: note, size: content.count)
            } else {
                completion?(nil)
            }
        }
    }

    func update(origin: Note, content: String, completion: ChangeCompletion = nil) {
        guard content.count > 0 else { purge(notes: [origin], completion: completion); return }
        performUpdates(
            notes: [origin],
            content: content,
            completion: completion
        )
        Analytics.logEvent(updateNote: origin)
    }

    func addTag(tags: String, notes: [Note], completion: ChangeCompletion = nil) {
        performUpdates(
            notes: notes,
            newTags: tags,
            needUpdateDate: false,
            completion: completion
        )
        guard let origin = notes.first else { return }
        Analytics.logEvent(attachTagsTo: origin, tags: tags)
    }

    func removeTag(tags: String, notes: [Note], completion: ChangeCompletion = nil) {
        performUpdates(
            notes: notes,
            removeTags: tags,
            needUpdateDate: false,
            completion: completion
        )
    }

    func updateTag(tags: String, note: Note, completion: ChangeCompletion = nil) {
        performUpdates(
            notes: [note],
            changeTags: tags,
            needUpdateDate: false,
            completion: completion
        )
    }

    func remove(notes: [Note], completion: ChangeCompletion = nil) {
        performUpdates(notes: notes, isRemoved: true, needUpdateDate: false, completion: completion)
        guard let origin = notes.first else { return }
        Analytics.logEvent(deleteNote: origin)
    }

    func restore(notes: [Note], completion: ChangeCompletion = nil) {
        performUpdates(
            notes: notes,
            isRemoved: false,
            needUpdateDate: false,
            completion: completion
        )
    }

    func pinNote(notes: [Note], completion: ChangeCompletion = nil) {
        performUpdates(
            notes: notes,
            isPinned: 1,
            needUpdateDate: false,
            completion: completion
        )
    }

    func unPinNote(notes: [Note], completion: ChangeCompletion = nil) {
        performUpdates(
            notes: notes,
            isPinned: 0,
            needUpdateDate: false,
            completion: completion
        )
    }

    func lockNote(notes: [Note], completion: ChangeCompletion) {
        performUpdates(
            notes: notes,
            isLocked: true,
            needUpdateDate: false,
            completion: completion
        )
    }

    func unlockNote(notes: [Note], completion: ChangeCompletion = nil) {
        performUpdates(
            notes: notes,
            isLocked: false,
            needUpdateDate: false,
            completion: completion
        )
    }

    func purge(notes: [Note], completion: ChangeCompletion = nil) {
        performUpdates(
            notes: notes,
            isPurged: true,
            needUpdateDate: false,
            completion: completion
        )
    }

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

        performUpdates(
            notes: [origin],
            content: content,
            tags: tagSet.joined(),
            completion: completion
        )
        Analytics.logEvent(mergeNote: notes)
        purge(notes: deletes)
    }

    func move(notes: [Note], to destination: Folder, completion: ChangeCompletion) {
        context.perform { [weak self] in
            guard let self = self else { return }
            notes.forEach {
                $0.folder = destination
                $0.markUploadReserved()
            }
            completion?(self.context.saveOrRollback())
        }
    }
}

extension NoteHandlable {

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

    func performUpdates(
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
        completion: ChangeCompletion = nil) {

        context.perform { [weak self] in
            guard let self = self else { return }
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
                            if isLocked {
                                note.tags = "\(note.tags ?? "")🔒"
                            } else {
                                note.tags = (note.tags ?? "").splitedEmojis.filter { $0 != "🔒" }.joined()
                            }
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
                if self.saveOrRollback(), let completion = completion {
                    DispatchQueue.main.async {
                        completion(true)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    if let completion = completion {
                        completion(false)
                    }
                }
            }
        }
    }

    func syncUpdateContent(note: Note, content: String) {
        context.performAndWait {
            do {
                guard let note = try context.existingObject(with: note.objectID) as? Note else { return }
                note.content = content
                note.modifiedAt = Date()
                note.markUploadReserved()
            } catch {
                // TODO:
                print(error)
            }
        }
    }

    func saveIfNeeded() {
        context.saveOrRollback()
    }
}
