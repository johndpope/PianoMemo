//
//  Writable.swift
//  Piano
//
//  Created by hoemoon on 30/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData

typealias ChangeCompletion = (() -> Void)?

protocol Writable: class {
    var backgroundContext: NSManagedObjectContext! { get }

    func create(content: String, tags: String, completion: ((Note) -> Void)?)
    func update(origin: Note, content: String, completion: ChangeCompletion)
    func update(origin: Note, newTags: String, completion: ChangeCompletion)
    func remove(origin: Note, completion: ChangeCompletion)
    func restore(origin: Note, completion: ChangeCompletion)
    func pinNote(origin: Note, completion: ChangeCompletion)
    func unPinNote(origin: Note, completion: ChangeCompletion)
    func lockNote(origin: Note, completion: ChangeCompletion)
    func unlockNote(origin: Note, completion: ChangeCompletion)
    func purge(notes: [Note], completion: ChangeCompletion)
    func merge(notes: [Note], completion: ChangeCompletion)
}

protocol Readable: class {
    var viewContext: NSManagedObjectContext! { get }
}

extension Writable {
    func create(content: String, tags: String, completion: ((Note) -> Void)? = nil) {
        backgroundContext.perform {
            let note = Note.insert(into: self.backgroundContext, content: content, tags: tags)
            self.saveOrRollback()
            completion?(note)
        }
    }

    func update(origin: Note, content: String, completion: ChangeCompletion = nil) {
        perfromUpdate(
            origin: origin,
            content: content,
            completion: completion
        )
    }

    func update(origin: Note, newTags: String, completion: ChangeCompletion = nil) {
        perfromUpdate(
            origin: origin,
            tags: newTags,
            needUpdateDate: false,
            completion: completion
        )
    }

    func remove(origin: Note, completion: ChangeCompletion = nil) {
        perfromUpdate(origin: origin, isRemoved: true, completion: completion)
    }

    func restore(origin: Note, completion: ChangeCompletion = nil) {
        perfromUpdate(
            origin: origin,
            isRemoved: false,
            completion: completion
        )
    }

    func pinNote(origin: Note, completion: ChangeCompletion = nil) {
        perfromUpdate(
            origin: origin,
            isPinned: 1,
            needUpdateDate: false,
            completion: completion
        )
    }

    func unPinNote(origin: Note, completion: ChangeCompletion = nil) {
        perfromUpdate(
            origin: origin,
            isPinned: 0,
            needUpdateDate: false,
            completion: completion
        )
    }

    func lockNote(origin: Note, completion: ChangeCompletion) {
        let tags = origin.tags ?? ""
        perfromUpdate(
            origin: origin,
            tags: "\(tags)🔒",
            needUpdateDate: false,
            completion: completion
        )
    }

    func unlockNote(origin: Note, completion: ChangeCompletion = nil) {
        let tags = origin.tags ?? ""
        perfromUpdate(
            origin: origin,
            tags: tags.splitedEmojis.filter { $0 != "🔒" }.joined(),
            needUpdateDate: false,
            completion: completion
        )
    }
    func purge(notes: [Note], completion: ChangeCompletion = nil) {
        backgroundContext.performAndWait {
            for note in notes {
                do {
                    if let note = try backgroundContext.existingObject(with: note.objectID) as? Note {
                        note.markForRemoteDeletion()
                        saveOrRollback()
                    }
                } catch {
                    print(error)
                }
            }
        }
        completion?()
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

        perfromUpdate(
            origin: origin,
            content: content,
            tags: tagSet.joined(),
            completion: completion
        )
        purge(notes: deletes)
    }
}

extension Writable {
    private func saveOrRollback() {
        guard backgroundContext.hasChanges else { return }
        do {
            try backgroundContext.save()
        } catch {
            backgroundContext.rollback()
        }
    }

    func perfromUpdate(
        origin: Note,
        content: String? = nil,
        isRemoved: Bool? = nil,
        isLocked: Bool? = nil,
        isPinned: Int? = nil,
        tags: String? = nil,
        needUpdateDate: Bool = true,
        isShared: Bool? = nil,
        completion: ChangeCompletion = nil) {

        backgroundContext.perform {
            do {
                let object = try self.backgroundContext.existingObject(with: origin.objectID)
                guard let note = object as? Note else { return }
                if let isRemoved = isRemoved {
                    note.isRemoved = isRemoved
                }
                if let content = content {
                    note.content = content
                }
                //  if let isLocked = isLocked {
                //      note.isLocked = isLocked
                //  }
                if let isPinned = isPinned {
                    note.isPinned = Int64(isPinned)
                }
                if let tags = tags {
                    note.tags = tags
                }
                if let isShared = isShared {
                    note.isShared = isShared
                }
                if needUpdateDate {
                    note.modifiedAt = Date() as NSDate
                }
                note.markUploadReserved()
                self.saveOrRollback()

                if let completion = completion {
                    DispatchQueue.main.async {
                        completion()
                    }
                }

            } catch {
                print(error)
            }
        }
    }
}

extension MasterViewController: Writable, Readable {}
