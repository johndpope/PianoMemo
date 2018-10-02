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
    var publicBackgroundContext: NSManagedObjectContext { get }
    var persistentContainer: NSPersistentContainer { get }
    var resultsController: NSFetchedResultsController<Note> { get }

    func addNote(_ record: CKRecord)
    func increaseFetchLimit(count: Int)
    func create(with attributedString: NSAttributedString,
                completionHandler: ((_ note: Note) -> Void)?)
    func fetch(with keyword: String, completionHandler: @escaping ([Note]) -> Void)
}

class LocalStorageService: LocalStorageServiceDelegate {
    weak var remoteStorageServiceDelegate: RemoteStorageServiceDelegate!

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Light")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    private lazy var privateBackgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.name = "private background context"
        return context
    }()

    lazy var publicBackgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.name = "public background context"
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

    private lazy var fetchOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    lazy var resultsController: NSFetchedResultsController<Note> = {
        let controller = NSFetchedResultsController(
            fetchRequest: noteFetchRequest,
            managedObjectContext: publicBackgroundContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        return controller
    }()

    init() {
        addObserverToPublicContext()
    }

    private func addObserverToPublicContext() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didSavePublicContext(_:)),
            name: .NSManagedObjectContextDidSave,
            object: publicBackgroundContext
        )
    }

    @objc func didSavePublicContext(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }

        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<Note>,
            inserts.count > 0 {
            upload(with: inserts)
        }

        if let updates = userInfo[NSUpdatedObjectsKey] as? Set<Note>,
            updates.count > 0 {
            upload(with: updates)
        }

        if let deletes = userInfo[NSDeletedObjectsKey] as? Set<Note>,
            deletes.count > 0 {
            // TODO:
        }
    }

    private func upload(with notes: Set<Note>) {
        let passedNotes = notes.compactMap {
            privateBackgroundContext.object(with: $0.objectID) as? Note
        }

        remoteStorageServiceDelegate.upload(notes: passedNotes) { [weak self] records, error in
            if error == nil {
                self?.updateMetaData(records: records)
                self?.privateBackgroundContext.saveIfNeeded()
                notes.forEach {
                    self?.publicBackgroundContext.refresh($0, mergeChanges: true)
                }
            } else {
                // TODO: 에러처리
            }
        }
    }

    private func updateMetaData(records: [CKRecord]) {
        for record in records {
            if let note = privateBackgroundContext.note(with: record.recordID) {
                note.createdAt = record.creationDate
                note.createdBy = record.creatorUserRecordID
                note.modifiedAt = record.modificationDate
                note.modifiedBy = record.lastModifiedUserRecordID
                note.recordArchive = record.archived
            }
        }
    }

    func fetch(with keyword: String, completionHandler: @escaping ([Note]) -> Void) {
        let fetchOperation = FetchNoteOperation(controller: resultsController) { notes in
            completionHandler(notes)
        }
        fetchOperation.setRequest(with: keyword)
        if fetchOperationQueue.operationCount > 0 {
            fetchOperationQueue.cancelAllOperations()
        }
        fetchOperationQueue.addOperation(fetchOperation)
    }

    func create(with attributedString: NSAttributedString,
                completionHandler: ((_ note: Note) -> Void)?) {
        // 컨텍스트와 노티에 대해 고민하기
        let note = Note(context: privateBackgroundContext)
        note.createdAt = Date()
        note.save(from: attributedString)
        let passed = publicBackgroundContext.object(with: note.objectID)
        publicBackgroundContext.refresh(passed, mergeChanges: true)
        completionHandler?(note)
    }

    func increaseFetchLimit(count: Int) {
        noteFetchRequest.fetchLimit += count
    }

    // 있는 경우 갱신하고, 없는 경우 생성한다.
    func addNote(_ record: CKRecord) {
        typealias Field = RemoteStorageSerevice.NoteFields
        if let note = privateBackgroundContext.note(with: record.recordID) {
            let note = notlify(from: record, to: note)
            privateBackgroundContext.saveIfNeeded()
            let passed = publicBackgroundContext.object(with: note.objectID)
            publicBackgroundContext.refresh(passed, mergeChanges: true)

        } else {
            let empty = Note(context: privateBackgroundContext)
            let note = notlify(from: record, to: empty)
            privateBackgroundContext.saveIfNeeded()
            let passed = publicBackgroundContext.object(with: note.objectID)
            publicBackgroundContext.refresh(passed, mergeChanges: true)
        }
    }

    private func notlify(from record: CKRecord, to note: Note) -> Note {
        typealias Field = RemoteStorageSerevice.NoteFields
        note.attributeData = record[Field.attributeData] as? Data
        note.content = record[Field.content] as? String
        note.isTrash = (record[Field.isTrash] as? Int ?? 0) == 1 ? true : false
        note.location = record[Field.location] as? CLLocation
        note.recordID = record.recordID

        note.createdAt = record.creationDate
        note.createdBy = record.creatorUserRecordID
        note.modifiedAt = record.modificationDate
        note.modifiedBy = record.lastModifiedUserRecordID

        note.recordArchive = record.archived
        return note
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
