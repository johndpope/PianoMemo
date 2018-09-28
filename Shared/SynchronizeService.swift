//
//  SynchronizeController.swift
//  Piano
//
//  Created by hoemoon on 26/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

/// 실제로 프로그래머가 호출하는 모든 데이터 조작 인터페이스를 제공
// TODO: 로컬, 리모트 스토리지 서비스는 나중에 분리하기

protocol SynchronizeServiceType: class {
    var resultsController: NSFetchedResultsController<Note> { get }
    var publicBackgroundContext: NSManagedObjectContext { get }

    func fetch(with keyword: String, completionHandler: @escaping ([Note]) -> Void)
    func setFetchResultsControllerDelegate(with delegate: NSFetchedResultsControllerDelegate)
    func increaseFetchLimit(count: Int)
    func create(with attributedString: NSAttributedString,
                completionHandler: ((_ note: Note) -> Void)?)
}

class SynchronizeService: SynchronizeServiceType {

    typealias Fields = RemoteStorageSerevice.NoteFields
    // MARK: private memeber
    private let persistentContainer: NSPersistentContainer
    private let localStorageService: LocalStorgeServiceType
    private let remoteStorageService: RemoteStorageServiceType

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

    private lazy var privateBackgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.name = "private background context"
        return context
    }()

    // MARK:

    lazy var publicBackgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.name = "public background context"
        return context
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

    init(persistentContainer: NSPersistentContainer,
        localStorageService: LocalStorgeServiceType = LocalStorageService(),
         remoteStorageService: RemoteStorageSerevice = RemoteStorageSerevice()) {

        self.persistentContainer = persistentContainer
        self.localStorageService = localStorageService
        self.remoteStorageService = remoteStorageService

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

    func setFetchResultsControllerDelegate(with delegate: NSFetchedResultsControllerDelegate) {
        self.resultsController.delegate = delegate
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

    func increaseFetchLimit(count: Int) {
        noteFetchRequest.fetchLimit += count
    }

    func create(with attributedString: NSAttributedString,
                completionHandler: ((_ note: Note) -> Void)?) {
        let note = Note(context: publicBackgroundContext)
        note.createdAt = Date()
        note.save(from: attributedString)
        completionHandler?(note)
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

        remoteStorageService.upload(notes: passedNotes) { [weak self] records, error in
            if error == nil {
                self?.updateMetaData(records: records)
                self?.privateBackgroundContext.saveIfNeeded()
                notes.forEach {
                    self?.publicBackgroundContext.refresh($0, mergeChanges: true)
                }
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
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.requiresSecureCoding = true
        self.encodeSystemFields(with: archiver)
        archiver.finishEncoding()
        return Data(referencing: data)
    }
}
