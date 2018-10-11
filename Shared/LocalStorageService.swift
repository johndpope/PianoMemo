//
//  LocalStorageService.swift
//  Piano
//
//  Created by hoemoon on 26/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

/// 로컬 저장소 상태를 변화시키는 모든 인터페이스 제공

protocol LocalStorageServiceDelegate: class {
    var mainResultsController: NSFetchedResultsController<Note> { get }
    var trashResultsController: NSFetchedResultsController<Note> { get }
    var mergeables: [Note]? { get }

    func setup()
    func search(
        with keyword: String,
        completion: @escaping ([Note]) -> Void)

    // user initiated + remote request
    func create(string: String)
    func create(with attributedString: NSAttributedString)
    func update(
        note origin: Note,
        with attributedString: NSAttributedString?,
        moveTrash: Bool?)
    func remove(note: Note)
    func restore(note: Note)
    func purge(note: Note)
    func purgeAll()
    func restoreAll()
    func merge(origin: Note, deletes: [Note])

    // user initiated, don't remote request
    func lockNote(_ note: Note)
    func unlockNote(_ note: Note)

    // server initiated operation
    func add(_ record: CKRecord)
    func purge(recordID: CKRecord.ID)

    func increaseFetchLimit(count: Int)
    func increaseTrashFetchLimit(count: Int)

    func saveContext()
}

class LocalStorageService: NSObject, LocalStorageServiceDelegate {

    weak var remoteStorageServiceDelegate: RemoteStorageServiceDelegate!

    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Light")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    private lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.name = "foregroundContext context"
        return context
    }()

    private lazy var noteFetchRequest: NSFetchRequest<Note> = {
        let request:NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
        request.predicate = NSPredicate(format: "isRemoved == false")
        request.fetchLimit = 100
        request.sortDescriptors = [sort]
        return request
    }()
    private lazy var trashFetchRequest: NSFetchRequest<Note> = {
        let request:NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
        request.predicate = NSPredicate(format: "isRemoved == true")
        request.sortDescriptors = [sort]
        return request
    }()

    // MARK: operation queue
    private lazy var searchOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    @objc private lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    // MARK: results controller
    lazy var mainResultsController: NSFetchedResultsController<Note> = {
        let controller = NSFetchedResultsController(
            fetchRequest: noteFetchRequest,
            managedObjectContext: backgroundContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        return controller
    }()

    lazy var trashResultsController: NSFetchedResultsController<Note> = {
        let controller = NSFetchedResultsController(
            fetchRequest: trashFetchRequest,
            managedObjectContext: backgroundContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        return controller
    }()

    func setup() {
        deleteMemosIfPassOneMonth()
        updateOwnerInfo()
    }

    private func updateOwnerInfo() {
//        let request: NSFetchRequest<Note> = Note.fetchRequest()
//        let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
//        let predicates = [
//            NSPredicate(format: "createdBy != nil"),
//            NSPredicate(format: "ownerID == nil")
//        ]
//        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
//        request.sortDescriptors = [sort]
//
//        if let fetched = try? backgroundContext.fetch(request) {
//            guard fetched.count > 0 else { return }
//            for note in fetched {
//                if let recordID = note.createdBy as? CKRecord.ID {
//                    remoteStorageServiceDelegate
//                        .requestUserIdentity(userRecordID: recordID) {
//                            [weak self] identity, error in
//                            guard let self = self else { return }
//                            if error == nil {
//                                note.ownerID = identity
//                                self.backgroundContext.saveIfNeeded()
//                            }
//                    }
//                }
//            }
//        }
    }

    // MARK:

    func search(with keyword: String, completion: @escaping ([Note]) -> Void) {
        let fetchOperation = FetchNoteOperation(controller: mainResultsController) { notes in
            completion(notes)
        }
        fetchOperation.setRequest(with: keyword)
        if searchOperationQueue.operationCount > 0 {
            searchOperationQueue.cancelAllOperations()
        }
        searchOperationQueue.addOperation(fetchOperation)
    }

    // MARK: User initiated operation + remote request

    func create(with attributedString: NSAttributedString) {
        create(string: attributedString.deformatted)
    }

    func create(string: String) {
        let create = CreateOperation(
            string: string,
            context: backgroundContext
        )
        let remoteRequest = ModifyRequestOperation(
            privateDatabase: remoteStorageServiceDelegate.privateDatabase,
            sharedDatabase: remoteStorageServiceDelegate.sharedDatabase
        )
        let resultsHandler = ResultsHandleOperation(
            operationQueue: operationQueue,
            context: backgroundContext
        )
        remoteRequest.addDependency(create)
        resultsHandler.addDependency(remoteRequest)
        operationQueue.addOperations([create, remoteRequest, resultsHandler], waitUntilFinished: false)
    }

    func update(
        note origin: Note,
        with attributedString: NSAttributedString?,
        moveTrash: Bool?) {

        let update = UpdateOperation(
            note: origin,
            attributedString: attributedString,
            isRemoved: moveTrash
        )
        let remoteRequest = ModifyRequestOperation(
            privateDatabase: remoteStorageServiceDelegate.privateDatabase,
            sharedDatabase: remoteStorageServiceDelegate.sharedDatabase
        )
        let resultsHandler = ResultsHandleOperation(
            operationQueue: operationQueue,
            context: backgroundContext
        )
        remoteRequest.addDependency(update)
        resultsHandler.addDependency(remoteRequest)
        operationQueue.addOperations([update, remoteRequest, resultsHandler], waitUntilFinished: false)
    }

    func remove(note: Note) {
        update(note: note, with: nil, moveTrash: true)
    }

    func restore(note: Note) {
        update(note: note, with: nil, moveTrash: false)
    }

    func purge(note: Note) {
        let purge = PurgeOperation(note: note, context: backgroundContext)
        let remoteRequest = ModifyRequestOperation(
            privateDatabase: remoteStorageServiceDelegate.privateDatabase,
            sharedDatabase: remoteStorageServiceDelegate.sharedDatabase
        )
        let resultsHandler = ResultsHandleOperation(
            operationQueue: operationQueue,
            context: backgroundContext
        )
        remoteRequest.addDependency(purge)
        resultsHandler.addDependency(remoteRequest)
        operationQueue.addOperations([purge, remoteRequest, resultsHandler], waitUntilFinished: false)
    }

    func purgeAll() {
        trashResultsController.fetchedObjects?.forEach {
            purge(note: $0)
        }
    }

    func restoreAll() {
        trashResultsController.fetchedObjects?.forEach {
            update(note: $0, with: nil, moveTrash: false)
        }
    }

    func merge(origin: Note, deletes: [Note]) {
        guard var content = origin.content else { return }
        deletes.forEach {
            let noteContent = $0.content ?? ""
            if noteContent.trimmingCharacters(in: .newlines).count != 0 {
                content.append("\n" + noteContent)
            }
        }

        let update = UpdateOperation(note: origin, string: content)
        let remoteRequest = ModifyRequestOperation(
            privateDatabase: remoteStorageServiceDelegate.privateDatabase,
            sharedDatabase: remoteStorageServiceDelegate.sharedDatabase
        )
        remoteRequest.addDependency(update)
        operationQueue.addOperations([update, remoteRequest], waitUntilFinished: false)

        for delete in deletes {
            let remoteRequest = ModifyRequestOperation(
                privateDatabase: remoteStorageServiceDelegate.privateDatabase,
                sharedDatabase: remoteStorageServiceDelegate.sharedDatabase
            )
            let purge = PurgeOperation(note: delete, context: backgroundContext)
            purge.addDependency(update)
            remoteRequest.addDependency(purge)
            operationQueue.addOperations([remoteRequest, purge], waitUntilFinished: false)
        }
    }

    // MARK: User initiated operation, don't remote request

    func lockNote(_ note: Note) {
        let content = Preference.lockStr + (note.content ?? "")
        let update = UpdateOperation(note: note, string: content, isLocked: true, isLatest: false)
        operationQueue.addOperation(update)
    }

    func unlockNote(_ note: Note) {
        if var content = note.content {
            content.removeCharacters(strings: [Preference.lockStr])
            let update = UpdateOperation(note: note, string: content, isLocked: false, isLatest: false)
            operationQueue.addOperation(update)
        }
    }

    // MARK: server initiated operation

    // 있는 경우 갱신하고, 없는 경우 생성한다.
    func add(_ record: CKRecord) {
        let add = AddOperation(record, context: backgroundContext)
        operationQueue.addOperation(add)
    }

    func purge(recordID: CKRecord.ID) {
        let purge = PurgeOperation(recordID: recordID, context: backgroundContext)
        operationQueue.addOperation(purge)
    }

    private func deleteMemosIfPassOneMonth() {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.predicate = NSPredicate(format: "isRemoved == true AND modifiedAt < %@", NSDate(timeIntervalSinceNow: -3600 * 24 * 30))
        let batchDelete = NSBatchDeleteRequest(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult>)
        batchDelete.affectedStores = persistentContainer.persistentStoreCoordinator.persistentStores
        batchDelete.resultType = .resultTypeCount
        do {
            let batchResult = try persistentContainer.viewContext.execute(batchDelete) as! NSBatchDeleteResult
            print("record deleted \(String(describing: batchResult.result))")
        } catch {
            print("could not delete \(error.localizedDescription)")
        }
    }

    func increaseFetchLimit(count: Int) {
        noteFetchRequest.fetchLimit += count
    }

    func increaseTrashFetchLimit(count: Int) {
        trashFetchRequest.fetchLimit += count
    }

    var mergeables: [Note]? {
        let request: NSFetchRequest<Note> = {
            let request:NSFetchRequest<Note> = Note.fetchRequest()
            let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
            request.predicate = NSPredicate(format: "isRemoved == false")
            request.sortDescriptors = [sort]
            return request
        }()
        do {
            return try backgroundContext.fetch(request)
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }

    func saveContext() {
        if backgroundContext.hasChanges {
            do {
                try backgroundContext.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

extension LocalStorageService {
    // MARK: helper
    /**
     잠금해제와 같은, 컨텐트 자체가 변화해야하는 경우에 사용되는 메서드
     중요) modifiedDate는 변화하지 않는다.
     */
    private func modify(note origin: Note,
                        text: String,
                        isLatest: Bool) {
        guard let context = origin.managedObjectContext else { return }
        context.performAndWait {
            let (title, subTitle) = text.titles
            origin.title = title
            origin.subTitle = subTitle
            origin.content = text

            if isLatest {
                origin.modifiedAt = Date()
            }
            
            context.saveIfNeeded()
        }
    }
}

