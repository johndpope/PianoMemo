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
    var backgroundContext: NSManagedObjectContext { get }
    var emojiTags: [String] { get set }

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

    // only local change
    func update(note: Note, isShared: Bool, completion: @escaping () -> Void)

    func increaseFetchLimit(count: Int)
    func increaseTrashFetchLimit(count: Int)

    func saveContext()
    func note(url: URL, completion: @escaping (Note?) -> Void)

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

    let keyValueStore = NSUbiquitousKeyValueStore()

    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    lazy var backgroundContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = viewContext
        context.name = "background context"
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
    private lazy var searchQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    lazy var serialQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    // MARK: results controller
    lazy var mainResultsController: NSFetchedResultsController<Note> = {
        let controller = NSFetchedResultsController(
            fetchRequest: noteFetchRequest,
            managedObjectContext: viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        return controller
    }()

    lazy var trashResultsController: NSFetchedResultsController<Note> = {
        let controller = NSFetchedResultsController(
            fetchRequest: trashFetchRequest,
            managedObjectContext: viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        return controller
    }()

    var emojiTags: [String] {
        get {
            if let value = keyValueStore.array(forKey: "emojiTags") as? [String] {
                return value
            } else {
                keyValueStore.set(["❤️"], forKey: "emojiTags")
                keyValueStore.synchronize()
                return keyValueStore.array(forKey: "emojiTags") as! [String]
            }
        }
        set {
            keyValueStore.set(newValue, forKey: "emojiTags")
            keyValueStore.synchronize()
        }
    }

    func setup() {
        keyValueStore.synchronize()
        deleteMemosIfPassOneMonth()
        addTutorialsIfNeeded()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(synchronizeKeyStore(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: nil
        )
    }

    @objc func synchronizeKeyStore(_ notificaiton: Notification) {
        keyValueStore.synchronize()
    }

    // MARK:

    func search(keyword: String, tags: String, completion: @escaping () -> Void) {
        let operation = FetchNoteOperation(controller: mainResultsController, completion: completion)
        operation.setRequest(keyword: keyword, tags: tags)
        searchQueue.addOperation(operation)
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
            context: viewContext,
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
        guard notes.count > 0 else { completion(); return }
        let purge = PurgeOperation(
            notes: notes,
            context: viewContext,
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
    // 1. accept한 경우
    // 2. 수정 / 생성 노티 받은 경우
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
//            add.completionBlock = {
//                NotificationCenter.default
//                    .post(name: .resolveContent, object: nil)
//            }
        }
    }

    func purge(recordID: CKRecord.ID) {
        let purge = PurgeOperation(recordIDs: [recordID], context: backgroundContext) {}
        serialQueue.addOperation(purge)
    }

    func update(note: Note, isShared: Bool, completion: @escaping () -> Void) {
        let update = UpdateOperation(
            note: note,
            context: viewContext,
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

    private func deleteMemosIfPassOneMonth() {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.predicate = NSPredicate(format: "isRemoved == true AND modifiedAt < %@", NSDate(timeIntervalSinceNow: -3600 * 24 * 30))
        if let fetched = try? backgroundContext.fetch(request) {
            purge(notes: fetched) {

            }
        }
    }
    
    private func addTutorialsIfNeeded() {
        guard keyValueStore.bool(forKey: "didAddTutorials") == false else { return }
        do {
            let noteCount = try backgroundContext.count(for: noteFetchRequest)
            if noteCount == 0 {
                keyValueStore.set(true, forKey: "didAddTutorials")
                keyValueStore.synchronize()
                create(string: "tutorial5".loc, tags: "", completion: { [weak self] in
                    guard let self = self else { return }
                    self.create(string: "tutorial4".loc, tags: "", completion: {
                        self.create(string: "tutorial1".loc, tags: "❤️", completion: {
                            self.create(string: "tutorial2".loc, tags: "❤️", completion: {
                                self.create(string: "tutorial3".loc, tags: "❤️", completion: {
                                })
                            })
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
        request.predicate = NSPredicate(format: "isRemoved == false && isShared == false && SELF != %@", originNote)
        request.sortDescriptors = [sort]
        
        do {
            return try persistentContainer.viewContext.fetch(request)
        } catch {
            print(error.localizedDescription)
        }
        return []
    }

    func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
