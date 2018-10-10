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
import DifferenceKit

protocol UIRefreshDelegate: class {
    func refreshUI(with target: [NoteWrapper], animated: Bool, completion: @escaping () -> Void)
}

/// 로컬 저장소 상태를 변화시키는 모든 인터페이스 제공

protocol LocalStorageServiceDelegate: class {
    var mainResultsController: NSFetchedResultsController<Note> { get }
    var mainRefreshDelegate: UIRefreshDelegate! { get set }
    var trashRefreshDelegate: UIRefreshDelegate! { get set }
    var trashResultsController: NSFetchedResultsController<Note> { get }

    func setup()
    func search(
        with keyword: String,
        completion: @escaping ([Note]) -> Void)

    // user initiated + remote request
    func create(with attributedString: NSAttributedString)
    func update(
        note origin: Note,
        with attributedString: NSAttributedString?,
        moveTrash: Bool?)
    func delete(note: Note)
    func restore(note: Note)
    func purge(note: Note)
    func purgeAll()
    func restoreAll()

    // user initiated, don't remote request
    func lockNote(_ note: Note)
    func unlockNote(_ note: Note)

    // server initiated operation
    func add(_ record: CKRecord)
    func purge(recordID: CKRecord.ID)

    func increaseFetchLimit(count: Int)
    func increaseTrashFetchLimit(count: Int)

    func mergeableNotes(with origin: Note) -> [Note]?
    func merge(origin: Note, deletes: [Note], completion: @escaping () -> Void)
    func saveContext()
}

class LocalStorageService: NSObject, LocalStorageServiceDelegate {

    weak var remoteStorageServiceDelegate: RemoteStorageServiceDelegate!
    weak var mainRefreshDelegate: UIRefreshDelegate!
    weak var trashRefreshDelegate: UIRefreshDelegate!

    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Light")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    private lazy var foregroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.name = "foregroundContext context"
        return context
    }()

    private lazy var noteFetchRequest: NSFetchRequest<Note> = {
        let request:NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
        request.predicate = NSPredicate(format: "isTrash == false")
        request.fetchLimit = 100
        request.sortDescriptors = [sort]
        return request
    }()
    private lazy var trashFetchRequest: NSFetchRequest<Note> = {
        let request:NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
        request.predicate = NSPredicate(format: "isTrash == true")
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
        return queue
    }()

    // MARK: results controller
    lazy var mainResultsController: NSFetchedResultsController<Note> = {
        let controller = NSFetchedResultsController(
            fetchRequest: noteFetchRequest,
            managedObjectContext: foregroundContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        return controller
    }()

    lazy var trashResultsController: NSFetchedResultsController<Note> = {
        let controller = NSFetchedResultsController(
            fetchRequest: trashFetchRequest,
            managedObjectContext: foregroundContext,
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
        let create = CreateOperation(
            attributedString: attributedString,
            context: foregroundContext
        )
        let remoteRequest = ModifyRequestOperation(
            privateDatabase: remoteStorageServiceDelegate.privateDatabase,
            sharedDatabase: remoteStorageServiceDelegate.sharedDatabase
        )
        let resultsHandler = ResultsHandleOperation(
            operationQueue: operationQueue,
            context: foregroundContext
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
            isTrash: moveTrash
        )
        let remoteRequest = ModifyRequestOperation(
            privateDatabase: remoteStorageServiceDelegate.privateDatabase,
            sharedDatabase: remoteStorageServiceDelegate.sharedDatabase
        )
        let resultsHandler = ResultsHandleOperation(
            operationQueue: operationQueue,
            context: foregroundContext
        )
        remoteRequest.addDependency(update)
        resultsHandler.addDependency(remoteRequest)
        operationQueue.addOperations([update, remoteRequest, resultsHandler], waitUntilFinished: false)
    }

    func delete(note: Note) {
        update(note: note, with: nil, moveTrash: true)
    }

    func restore(note: Note) {
        update(note: note, with: nil, moveTrash: false)
    }

    func purge(note: Note) {
        let purge = PurgeOperation(note: note)
        let remoteRequest = ModifyRequestOperation(
            privateDatabase: remoteStorageServiceDelegate.privateDatabase,
            sharedDatabase: remoteStorageServiceDelegate.sharedDatabase
        )
        let resultsHandler = ResultsHandleOperation(
            operationQueue: operationQueue,
            context: foregroundContext
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

    // MARK: User initiated operation, don't remote request

    func lockNote(_ note: Note) {
        note.title = Preference.lockStr + (note.title ?? "")
        note.content = Preference.lockStr + (note.content ?? "")
        modify(note: note, text: note.content!, needUIUpdate: false)
    }

    func unlockNote(_ note: Note) {
        if var content = note.content {
            content.removeCharacters(strings: [Preference.lockStr])
            modify(note: note, text: content, needUIUpdate: false)
        }
    }


    // MARK: server initiated operation

    // 있는 경우 갱신하고, 없는 경우 생성한다.
    func add(_ record: CKRecord) {
//        if let note = backgroundContext.note(with: record.recordID) {
//            notlify(from: record, to: note)
//        } else {
//            let empty = Note(context: backgroundContext)
//            notlify(from: record, to: empty)
//        }
//
//        backgroundContext.saveIfNeeded()
    }

//    func refreshUI(completion: @escaping () -> Void) {
//        foregroundContext.refreshAllObjects()
//
//        if trashRefreshDelegate != nil {
//            try? trashResultsController.performFetch()
//            if let fetched = trashResultsController.fetchedObjects {
//                trashRefreshDelegate.refreshUI(with: fetched.map { $0.wrapped }, animated: true, completion: completion)
//            }
//        }
//
//        if mainRefreshDelegate != nil {
//            try? mainResultsController.performFetch()
//            if let fetched = mainResultsController.fetchedObjects, fetched.count > 0 {
//                mainRefreshDelegate.refreshUI(with: fetched.map { $0.wrapped }, animated: true, completion: completion)
//            }
//        }
//    }

    func purge(recordID: CKRecord.ID) {
        //        if let note = backgroundContext.note(with: recordID) {
        //            backgroundContext.delete(note)
        //            backgroundContext.saveIfNeeded()
        //            refreshUI {}
        //        }
    }



    private func deleteMemosIfPassOneMonth() {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.predicate = NSPredicate(format: "isTrash == true AND modifiedAt < %@", NSDate(timeIntervalSinceNow: -3600 * 24 * 30))
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

    @discardableResult
    private func notlify(from record: CKRecord, to note: Note) -> Note {
        typealias Field = RemoteStorageSerevice.NoteFields
        note.content = record[Field.content] as? String
        note.isTrash = (record[Field.isTrash] as? Int ?? 0) == 1 ? true : false
        note.location = record[Field.location] as? CLLocation
        note.recordID = record.recordID

        note.createdAt = record.creationDate
        note.createdBy = record.creatorUserRecordID
        note.modifiedAt = record.modificationDate
        note.modifiedBy = record.lastModifiedUserRecordID

        note.recordArchive = record.archived

//        if let content = note.content {
//            let titles = content.titles
//            note.title = titles.0
//            note.subTitle = titles.1
//        }
        return note
    }

    func mergeableNotes(with origin: Note) -> [Note]? {
        let request: NSFetchRequest<Note> = {
            let request:NSFetchRequest<Note> = Note.fetchRequest()
            let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
            let predicate = NSPredicate(format: "isTrash == false && SELF != %@", origin)
            request.predicate = predicate
            request.sortDescriptors = [sort]
            return request
        }()
        do {
            return try foregroundContext.fetch(request)
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }

    func merge(origin: Note, deletes: [Note], completion: @escaping () -> Void) {
//        var content = origin.content ?? ""
//        deletes.forEach {
//            let noteContent = $0.content ?? ""
//            if noteContent.trimmingCharacters(in: .newlines).count != 0 {
//                content.append("\n" + noteContent)
//            }
//            foregroundContext.delete($0)
//        }
//
//        let (title, subTitle) = content.titles
//
//        origin.title = title
//        origin.subTitle = subTitle
//        origin.content = content
//        origin.hasEdit = true
//        origin.modifiedAt = Date()
//
//        refreshUI { [weak self] in
//            self?.foregroundContext.saveIfNeeded()
//            completion()
//        }
    }

    func saveContext() {
        if foregroundContext.hasChanges {
            do {
                try foregroundContext.save()
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
                        needUIUpdate: Bool) {
        guard let context = origin.managedObjectContext else { return }
        context.performAndWait {
            let (title, subTitle) = text.titles
            origin.title = title
            origin.subTitle = subTitle
            origin.content = text

            if needUIUpdate {
                origin.hasEdit = true
                origin.modifiedAt = Date()
            }
        }
        do {
            try context.save()
        } catch {
            print(error)
        }
    }
}

private extension NSManagedObjectContext {
    func note(with recordID: CKRecord.ID) -> Note? {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
        request.predicate = NSPredicate(format: "%K == %@", "recordID", recordID as CVarArg)
        request.fetchLimit = 1
        request.sortDescriptors = [sort]
        if let fetched = try? fetch(request), let note = fetched.first {
            return note
        }
        return nil
    }
}

private extension CKRecord {
    var archived: Data {
        let data = NSMutableData()
        let coder = NSKeyedArchiver(forWritingWith: data)
        coder.requiresSecureCoding = true
        self.encodeSystemFields(with: coder)
        coder.finishEncoding()
        return Data(referencing: data)
    }
}

