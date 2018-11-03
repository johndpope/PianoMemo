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
        deletes.forEach {
            let noteContent = $0.content ?? ""
            if noteContent.trimmingCharacters(in: .newlines).count != 0 {
                content.append("\n" + noteContent)
            }
        }

        update(note: origin, string: content, completion: completion)
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
                let note = self.backgroundContext.object(with: id) as? Note
                completion(note)
            }
        }
    }

    func saveContext() {
        saveContext(mainContext)
    }
}

extension LocalStorageService {
    func create(
        string: String,
        tags: String,
        completion: (() -> Void)? = nil) {

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

    func update(
        note origin: Note,
        string: String? = nil,
        isRemoved: Bool? = nil,
        isLocked: Bool? = nil,
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
