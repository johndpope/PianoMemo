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

protocol LocalDataManageDelegate: class {
    func create(
        string: String,
        tags: String,
        completion: @escaping () -> Void
    )
    func create(
        attributedString: NSAttributedString,
        tags: String,
        completion: @escaping () -> Void
    )
    func update(
        note: Note,
        with tags: String,
        completion: @escaping () -> Void
    )
    func update(
        note: Note,
        with: NSAttributedString,
        completion: @escaping () -> Void
    )
    func update(
        note: Note,
        isShared: Bool,
        completion: @escaping () -> Void
    )
    func remove(note: Note, completion: @escaping () -> Void)
    func restore(note: Note, completion: @escaping () -> Void)
    func purge(notes: [Note], completion: @escaping () -> Void)
    func purgeAll(completion: @escaping () -> Void)
    func merge(origin: Note, deletes: [Note], completion: @escaping () -> Void)
    func lockNote(_ note: Note, completion: @escaping () -> Void)
    func unlockNote(_ note: Note, completion: @escaping () -> Void)
    func note(url: URL, completion: @escaping (Note?) -> Void)

    func saveContext()
}

extension LocalStorageService: LocalDataManageDelegate {
    func create(
        attributedString: NSAttributedString,
        tags: String,
        completion: @escaping () -> Void) {

        create(string: attributedString.deformatted,
               tags: tags,
               completion: completion
        )
    }

    func update(
        note: Note,
        with tags: String,
        completion: @escaping () -> Void) {

        update(
            note: note,
            changedTags: tags,
            needModifyDate: false,
            completion: completion
        )
    }

    func update(note: Note,
                with: NSAttributedString,
                completion: @escaping () -> Void) {
        update(
            note: note,
            attributedString: with,
            completion: completion
        )
    }

    func remove(note: Note, completion: @escaping () -> Void) {
        update(note: note, isRemoved: true, completion: completion)
    }

    func restore(note: Note, completion: @escaping () -> Void) {
        update(note: note, isRemoved: false, completion: completion)
    }

    func lockNote(_ note: Note, completion: @escaping () -> Void) {
        update(note: note, isLocked: true, needModifyDate: false, completion: completion)
    }

    func unlockNote(_ note: Note, completion: @escaping () -> Void) {
        update(note: note, isLocked: false, needModifyDate: false, completion: completion)
    }

    func purge(notes: [Note], completion: @escaping () -> Void) {
        guard notes.count > 0 else { completion(); return }
        let purge = PurgeOperation(
            notes: notes,
            context: mainContext,
            completion: completion
        )
        let remoteRequest = ModifyRequestOperation(
            privateDatabase: syncController.privateDB,
            sharedDatabase: syncController.sharedDB
        )
        let resultsHandler = ResultsHandleOperation(
            operationQueue: serialQueue,
            backgroundContext: backgroundContext,
            mainContext: mainContext
        )
        remoteRequest.addDependency(purge)
        resultsHandler.addDependency(remoteRequest)
        serialQueue.addOperations([purge, remoteRequest, resultsHandler], waitUntilFinished: false)
    }

    func purgeAll(completion: @escaping () -> Void) {
        guard let notes = trashResultsController.fetchedObjects else { return }
        purge(notes: notes, completion: completion)
    }

    func merge(origin: Note, deletes: [Note], completion: @escaping () -> Void) {
        var content = origin.content ?? ""
        deletes.forEach {
            let noteContent = $0.content ?? ""
            if noteContent.trimmingCharacters(in: .newlines).count != 0 {
                content.append("\n" + noteContent)
            }
        }

        purge(notes: deletes) {}
        update(note: origin, string: content, completion: completion)
    }

    // MARK: server initiated operation
    // 1. accept한 경우
    // 2. 수정 / 생성 노티 받은 경우
    // deprecated
//    func add(_ record: CKRecord, isMine: Bool) {
//        let add = AddOperation(record, context: backgroundContext, isMine: isMine) {
//            [weak self] note in
//            guard let self = self else { return }
//            if self.needBypass {
//                if let note = note {
//                    OperationQueue.main.addOperation {
//                        self.shareAcceptable?.byPassList(note: note)
//                        self.needBypass = false
//                    }
//                }
//            } else {
//                NotificationCenter.default
//                    .post(name: .resolveContent, object: nil)
//            }
//        }
//        serialQueue.addOperation(add)
//    }

    func update(note: Note, isShared: Bool, completion: @escaping () -> Void) {
        let update = UpdateOperation(
            note: note,
            context: mainContext,
            needUpdateDate: false,
            isShared: isShared,
            completion: completion
        )
        serialQueue.addOperation(update)
    }

    func note(url: URL, completion: @escaping (Note?) -> Void) {
        if let id = persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url) {
            backgroundContext.performAndWait {
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
        completion: @escaping () -> Void) {

        let create = CreateOperation(
            content: string,
            tags: tags,
            context: mainContext,
            completion: completion
        )
        let remoteRequest = ModifyRequestOperation(
            privateDatabase: syncController.privateDB,
            sharedDatabase: syncController.sharedDB
        )
        let resultsHandler = ResultsHandleOperation(
            operationQueue: serialQueue,
            backgroundContext: backgroundContext,
            mainContext: mainContext
        )
        remoteRequest.addDependency(create)
        resultsHandler.addDependency(remoteRequest)
        serialQueue.addOperations([create, remoteRequest, resultsHandler], waitUntilFinished: false)
    }

    func update(
        note origin: Note,
        attributedString: NSAttributedString? = nil,
        string: String? = nil,
        isRemoved: Bool? = nil,
        isLocked: Bool? = nil,
        changedTags: String? = nil,
        needModifyDate: Bool = true,
        completion: @escaping () -> Void) {

        let update = UpdateOperation(
            note: origin,
            context: mainContext,
            attributedString: attributedString,
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
            operationQueue: serialQueue,
            backgroundContext: backgroundContext,
            mainContext: mainContext
        )
        remoteRequest.addDependency(update)
        resultsHandler.addDependency(remoteRequest)
        serialQueue.addOperations([update, remoteRequest, resultsHandler], waitUntilFinished: false)
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
