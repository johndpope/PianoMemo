//
//  Writable.swift
//  Piano
//
//  Created by hoemoon on 30/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData

typealias ChangeCompletion = ((Bool) -> Void)?

protocol Writable: class {
    var viewContext: NSManagedObjectContext! { get }
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

extension Writable {
    func create(content: String, tags: String, completion: ((Note) -> Void)? = nil) {
        backgroundContext.performChanges {
            let note = Note.insert(into: self.backgroundContext, content: content, tags: tags)
            completion?(note)
        }
    }
    
    func update(origin: Note, content: String, completion: ChangeCompletion = nil) {
        backgroundContext.update(
            origin: origin,
            content: content,
            completion: completion
        )
    }

    func update(origin: Note, newTags: String, completion: ChangeCompletion = nil) {
        backgroundContext.update(
            origin: origin,
            tags: newTags,
            needUpdateDate: false,
            completion: completion
        )
    }

    func remove(origin: Note, completion: ChangeCompletion = nil) {
        backgroundContext.update(origin: origin, isRemoved: true, completion: completion)
    }

    func restore(origin: Note, completion: ChangeCompletion = nil) {
        backgroundContext.update(
            origin: origin,
            isRemoved: false,
            completion: completion
        )
    }

    func pinNote(origin: Note, completion: ChangeCompletion = nil) {
        backgroundContext.update(
            origin: origin,
            isPinned: 1,
            needUpdateDate: false,
            completion: completion
        )
    }

    func unPinNote(origin: Note, completion: ChangeCompletion = nil) {
        backgroundContext.update(
            origin: origin,
            isPinned: 0,
            needUpdateDate: false,
            completion: completion
        )
    }

    func lockNote(origin: Note, completion: ChangeCompletion) {
        let tags = origin.tags ?? ""
        backgroundContext.update(origin: origin, tags: "\(tags)🔒", completion: completion)
    }

    func unlockNote(origin: Note, completion: ChangeCompletion = nil) {
        let tags = origin.tags ?? ""
        backgroundContext.update(
            origin: origin,
            tags: tags.splitedEmojis.filter { $0 != "🔒" }.joined(),
            completion: completion
        )
    }
    func purge(notes: [Note], completion: ChangeCompletion = nil) {
        backgroundContext.performChanges(block: {
            notes.forEach {
                $0.markForRemoteDeletion()
            }
        }, completion: completion)
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

        backgroundContext.update(
            origin: origin,
            content: content,
            tags: tagSet.joined()
        )
        purge(notes: deletes, completion: completion)
    }

}

extension MasterViewController: Writable {}
