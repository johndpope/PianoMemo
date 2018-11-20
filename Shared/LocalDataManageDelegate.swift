//
//  LocalDataManageDelegate.swift
//  Piano
//
//  Created by hoemoon on 23/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

extension LocalStorageService {
    func update(
        note: Note,
        tags: String,
        completion: (() -> Void)? = nil) {

        update(
            note: note,
            changedTags: tags,
            needModifyDate: false,
            completion: completion
        )
    }

    func remove(note: Note, completion: (() -> Void)? = nil) {
        update(note: note, isRemoved: true, completion: completion)
    }

    func restore(note: Note, completion: (() -> Void)? = nil) {
        update(note: note, isRemoved: false, completion: completion)
    }

    func pinNote(_ note: Note, completion: (() -> Void)? = nil) {
        update(note: note, isPinned: true, needModifyDate: false, completion: completion)
    }

    func unPinNote(_ note: Note, completion: (() -> Void)? = nil) {
        update(note: note, isPinned: false, needModifyDate: false, completion: completion)
    }

    func lockNote(_ note: Note, completion: (() -> Void)? = nil) {
        update(note: note, isLocked: true, needModifyDate: false, completion: completion)
    }

    func unlockNote(_ note: Note, completion: (() -> Void)? = nil) {
        update(note: note, isLocked: false, needModifyDate: false, completion: completion)
    }


    func purgeAll(completion: (() -> Void)? = nil) {
        guard let notes = trashResultsController.fetchedObjects else { return }
        purge(notes: notes, completion: completion)
    }

    func merge(origin: Note, deletes: [Note], completion: (() -> Void)? = nil) {
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

        update(note: origin, string: content, changedTags: tagSet.joined(), completion: completion)
        purge(notes: deletes) {}
    }


    func update(note: Note, isShared: Bool, completion: (() -> Void)? = nil) {
        let update = UpdateOperation(
            note: note,
            backgroudContext: backgroundContext,
            mainContext: mainContext,
            needUpdateDate: false,
            isShared: isShared,
            completion: completion
        )
        privateQueue.addOperation(update)
    }

    func note(url: URL, completion: @escaping (Note?) -> Void) {
        if let id = persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url) {
            backgroundContext.perform {
                if let object = try? self.backgroundContext.existingObject(with: id),
                    let note = object as? Note {
                    if note.isRemoved {
                        completion(nil)
                    } else {
                        completion(note)
                    }
                } else {
                    completion(nil)
                }
            }
        }
    }

    func saveContext() {
        saveContext(mainContext)
    }

    func upload(notes: [Note]) {
        let remoteRequest = ModifyRequestOperation(
            privateDatabase: syncController.privateDB,
            sharedDatabase: syncController.sharedDB
        )
        remoteRequest.recordsToSave = notes.map { $0.recodify() }

        let resultsHandler = ResultsHandleOperation(
            operationQueue: privateQueue,
            backgroundContext: backgroundContext,
            mainContext: mainContext
        )
        resultsHandler.addDependency(remoteRequest)
        privateQueue.addOperations(
            [remoteRequest, resultsHandler],
            waitUntilFinished: false
        )
    }
}

extension LocalStorageService {
    func create(
        string: String,
        tags: String,
        completion: ((Note) -> Void)? = nil) {

        let create = CreateOperation(
            content: string,
            tags: tags,
            backgroundContext: backgroundContext,
            mainContext: mainContext,
            completion: completion
        )
        let remoteRequest = ModifyRequestOperation(
            privateDatabase: syncController.privateDB,
            sharedDatabase: syncController.sharedDB
        )
        let resultsHandler = ResultsHandleOperation(
            operationQueue: privateQueue,
            backgroundContext: backgroundContext,
            mainContext: mainContext
        )
        remoteRequest.addDependency(create)
        resultsHandler.addDependency(remoteRequest)
        privateQueue.addOperations(
            [create, remoteRequest, resultsHandler],
            waitUntilFinished: false
        )
    }

    func createLocally(string: String, tags: String, completion: ((Note) -> Void)? = nil) {
        let create = CreateOperation(
            content: string,
            tags: tags,
            backgroundContext: backgroundContext,
            mainContext: mainContext,
            completion: completion
        )
        serialQueue.addOperation(create)
    }

    func update(
        note origin: Note,
        string: String? = nil,
        isRemoved: Bool? = nil,
        isLocked: Bool? = nil,
        isPinned: Bool? = nil,
        changedTags: String? = nil,
        needModifyDate: Bool = true,
        completion: (() -> Void)? = nil) {

        let update = UpdateOperation(
            note: origin,
            backgroudContext: backgroundContext,
            mainContext: mainContext,
            string: string,
            isRemoved: isRemoved,
            isLocked: isLocked,
            changedTags: changedTags,
            needUpdateDate: needModifyDate,
            completion: completion
        )
        let remoteRequest = ModifyRequestOperation(
            privateDatabase: syncController.privateDB,
            sharedDatabase: syncController.sharedDB
        )
        let resultsHandler = ResultsHandleOperation(
            operationQueue: privateQueue,
            backgroundContext: backgroundContext,
            mainContext: mainContext
        )
        remoteRequest.addDependency(update)
        resultsHandler.addDependency(remoteRequest)
        privateQueue.addOperations([update, remoteRequest, resultsHandler], waitUntilFinished: false)
    }

    func purge(notes: [Note], completion: (() -> Void)? = nil) {
        guard notes.count > 0 else { completion?(); return }
        let purge = PurgeOperation(
            notes: notes,
            backgroundContext: backgroundContext,
            mainContext: mainContext,
            completion: completion
        )
        let remoteRequest = ModifyRequestOperation(
            privateDatabase: syncController.privateDB,
            sharedDatabase: syncController.sharedDB
        )
        let resultsHandler = ResultsHandleOperation(
            operationQueue: privateQueue,
            backgroundContext: backgroundContext,
            mainContext: mainContext
        )
        remoteRequest.addDependency(purge)
        resultsHandler.addDependency(remoteRequest)
        privateQueue.addOperations(
            [purge, remoteRequest, resultsHandler],
            waitUntilFinished: false
        )
    }

    func saveContext(_ context: NSManagedObjectContext) {
        if context != mainContext {
            saveDerivedContext(context)
            return
        }
        guard context.hasChanges else { return }
        context.perform {
            do {
                try context.save()
            } catch let error as NSError {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }

    func saveDerivedContext(_ context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        context.perform {
            do {
                try context.save()
            } catch let error as NSError {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            self.saveContext(self.mainContext)
        }
    }
}

