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
    var serialQueue: OperationQueue { get }
    var shareAcceptable: ShareAcceptable? { get set }
    var needBypass: Bool { get set }

    func mergeables(originNote: Note) -> [Note]
    func setup()
    func search(keyword: String, tags: String, completion: @escaping () -> Void)

    // user initiated + remote request
    func create(string: String, tags: String, completion: @escaping () -> Void)
    func create(
        attributedString: NSAttributedString,
        tags: String,
        completion: @escaping () -> Void
    )
    func update(
        note origin: Note,
        attributedString: NSAttributedString?,
        string: String?,
        isRemoved: Bool?,
        isLocked: Bool?,
        changedTags: String?,
        needModifyDate: Bool,
        completion: @escaping () -> Void)
    func update(note: Note, with tags: String, completion: @escaping () -> Void)
    func remove(note: Note, completion: @escaping () -> Void)
    func restore(note: Note, completion: @escaping () -> Void)
    func purge(notes: [Note], completion: @escaping () -> Void)
    func purgeAll(completion: @escaping () -> Void)
    func merge(origin: Note, deletes: [Note], completion: @escaping () -> Void)
    func lockNote(_ note: Note, completion: @escaping () -> Void)
    func unlockNote(_ note: Note, completion: @escaping () -> Void)
    
    // server initiated operation
    func add(_ record: CKRecord, isMine: Bool)
    func purge(recordID: CKRecord.ID)

    func increaseFetchLimit(count: Int)
    func increaseTrashFetchLimit(count: Int)

    func saveContext()
}

class LocalStorageService: NSObject, LocalStorageServiceDelegate {
    
    var needBypass: Bool = false
    weak var remoteStorageServiceDelegate: RemoteStorageServiceDelegate!
    weak var shareAcceptable: ShareAcceptable?

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

    @objc lazy var serialQueue: OperationQueue = {
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
        saveTutorialsIfNeeded()
    }

    // MARK:

    func search(keyword: String, tags: String, completion: @escaping () -> Void) {
        let fetchOperation = FetchNoteOperation(controller: mainResultsController) { completion() }
        fetchOperation.setRequest(keyword: keyword, tags: tags)
        if searchOperationQueue.operationCount > 0 {
            searchOperationQueue.cancelAllOperations()
        }
        searchOperationQueue.addOperation(fetchOperation)
    }

    // MARK: User initiated operation + remote request
    
    func create(
        attributedString: NSAttributedString,
        tags: String,
        completion: @escaping () -> Void) {

        create(string: attributedString.deformatted, tags: tags, completion: completion)
    }
    
    func create(
        string: String,
        tags: String,
        completion: @escaping () -> Void) {

        let create = CreateOperation(
            content: string,
            tags: tags,
            context: backgroundContext,
            completion: completion
        )
        let remoteRequest = ModifyRequestOperation(
            privateDatabase: remoteStorageServiceDelegate.privateDatabase,
            sharedDatabase: remoteStorageServiceDelegate.sharedDatabase
        )
        let resultsHandler = ResultsHandleOperation(
            operationQueue: serialQueue,
            context: backgroundContext
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
            attributedString: attributedString,
            string: string,
            isRemoved: isRemoved,
            isLocked: isLocked,
            changedTags: changedTags,
            needUpdateDate: needModifyDate,
            completion: completion
        )
        
        let remoteRequest = ModifyRequestOperation(
            privateDatabase: remoteStorageServiceDelegate.privateDatabase,
            sharedDatabase: remoteStorageServiceDelegate.sharedDatabase
        )
        let resultsHandler = ResultsHandleOperation(
            operationQueue: serialQueue,
            context: backgroundContext
        )
        remoteRequest.addDependency(update)
        resultsHandler.addDependency(remoteRequest)
        serialQueue.addOperations([update, remoteRequest, resultsHandler], waitUntilFinished: false)
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
        let purge = PurgeOperation(
            notes: notes,
            context: backgroundContext,
            completion: completion
        )
        let remoteRequest = ModifyRequestOperation(
            privateDatabase: remoteStorageServiceDelegate.privateDatabase,
            sharedDatabase: remoteStorageServiceDelegate.sharedDatabase
        )
        let resultsHandler = ResultsHandleOperation(
            operationQueue: serialQueue,
            context: backgroundContext
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

    // 있는 경우 갱신하고, 없는 경우 생성한다.
    func add(_ record: CKRecord, isMine: Bool) {
        let add = AddOperation(record, context: backgroundContext, isMine: isMine)
        serialQueue.addOperation(add)
        if needBypass {
            add.completionBlock = { [weak self] in
                if let note = add.note {
                    OperationQueue.main.addOperation {
                        self?.shareAcceptable?.byPassList(note: note)
                        self?.needBypass = false
                    }
                }
            }
        } else {
            add.completionBlock = {
                NotificationCenter.default
                    .post(name: .resolveContent, object: nil)
            }
        }
    }

    func purge(recordID: CKRecord.ID) {
        let purge = PurgeOperation(recordIDs: [recordID], context: backgroundContext) {}
        serialQueue.addOperation(purge)
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
    
    private func saveTutorialsIfNeeded() {
        do {
            let noteCount = try backgroundContext.count(for: noteFetchRequest)
            if noteCount == 0 {
                create(string: "tutorial1".loc, tags: "", completion: { [weak self] in
                    guard let self = self else { return }
                    self.create(string: "tutorial2".loc, tags: "", completion: {
                        self.create(string: "tutorial3".loc, tags: "❤️", completion: {
                        })
                    })
                })
            }
        } catch {
            print(error.localizedDescription)
        }
    }

    func increaseFetchLimit(count: Int) {
        noteFetchRequest.fetchLimit += count
    }

    func increaseTrashFetchLimit(count: Int) {
        trashFetchRequest.fetchLimit += count
    }
    
    func mergeables(originNote: Note) -> [Note] {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
        request.predicate = NSPredicate(format: "isRemoved == false && SELF != %@", originNote)
        request.sortDescriptors = [sort]
        
        do {
            return try backgroundContext.fetch(request)
        } catch {
            print(error.localizedDescription)
        }
        return []
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
