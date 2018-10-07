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
    func refreshUI(with target: [NoteWrapper])
}

/// 로컬 저장소 상태를 변화시키는 모든 인터페이스 제공

protocol LocalStorageServiceDelegate: class {
    var foregroundContext: NSManagedObjectContext { get }
    var mainResultsController: NSFetchedResultsController<Note> { get }
    var mainRefreshDelegate: UIRefreshDelegate! { get set }
    var trashRefreshDelegate: UIRefreshDelegate! { get set }
    var trashResultsController: NSFetchedResultsController<Note> { get }

    func addNote(_ record: CKRecord)
    func increaseFetchLimit(count: Int)
    func create(with attributedString: NSAttributedString,
                completionHandler: ((_ note: Note) -> Void)?)
    func fetch(with keyword: String, completionHandler: @escaping ([Note]) -> Void)
    func refreshUI()
    func update(note: Note, with attributedText: NSAttributedString, completion: @escaping (Note) -> Void)
    func purge(note: Note, completion: () -> Void)
    func purgeAll()
    func restoreAll()
    func increaseTrashFetchLimit(count: Int)
    func setup()
    func delete(note: Note)
    func unlockNote(_ note: Note, completion: (Note) -> Void)
    func lockNote(_ note: Note, completion: (Note) -> Void)
}

class LocalStorageService: LocalStorageServiceDelegate {
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

    lazy var foregroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.name = "foregroundContext context"
        return context
    }()

    private lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.name = "backgroundContext context"
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

    private lazy var fetchOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

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
        addObserverToForegroundContext()
        deleteMemosIfPassOneMonth()
    }

    private func addObserverToForegroundContext() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didSaveForeGroundContext(_:)),
            name: .NSManagedObjectContextDidSave,
            object: foregroundContext
        )
    }

    @objc func didSaveForeGroundContext(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }

        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<Note>,
            inserts.count > 0 {
            requestModify(insertsOrUpdates: inserts)
        }

        if let updates = userInfo[NSUpdatedObjectsKey] as? Set<Note>,
            updates.count > 0 {
            requestModify(insertsOrUpdates: updates)
        }

        if let deletes = userInfo[NSDeletedObjectsKey] as? Set<Note>,
            deletes.count > 0 {
            requestModify(deletes: deletes)
        }
    }

    private func requestModify(
        insertsOrUpdates: Set<Note>? = nil,
        deletes: Set<Note>? = nil) {

        func convert(_ notes: Set<Note>) -> Array<CKRecord> {
            let passedNotes = notes.compactMap {
                backgroundContext.object(with: $0.objectID) as? Note
            }
            return passedNotes.map { $0.recodify() }
        }

        if let insertsOrUpdates = insertsOrUpdates {
            remoteStorageServiceDelegate
                .requestModify(recordsToSave: convert(insertsOrUpdates), recordsToDelete: nil) {
                    [weak self] saves, _, error in
                    if let saves = saves, error == nil {
                        self?.updateMetaData(records: saves)
                        self?.backgroundContext.saveIfNeeded()
                        self?.refreshUI()
                    } else if let error = error {
                        print(error)
                        fatalError()
                    }
            }
        } else if let deletes = deletes {
            remoteStorageServiceDelegate
                .requestModify(recordsToSave: nil, recordsToDelete: convert(deletes)) {
                    [weak self] _, _, error in
                    if error == nil {
                        self?.backgroundContext.saveIfNeeded()
                        self?.refreshUI()
                    } else if let error = error {
                        print(error)
                        fatalError()
                    }
            }
        }
    }

    private func updateMetaData(records: [CKRecord]) {
        for record in records {
            if let note = backgroundContext.note(with: record.recordID) {
                note.createdAt = record.creationDate
                note.createdBy = record.creatorUserRecordID
                note.modifiedAt = record.modificationDate
                note.modifiedBy = record.lastModifiedUserRecordID
                note.recordArchive = record.archived
            }
        }
    }

    func fetch(with keyword: String, completionHandler: @escaping ([Note]) -> Void) {
        print("keyword :", keyword)
        let fetchOperation = FetchNoteOperation(controller: mainResultsController) { notes in
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
        foregroundContext.performAndWait {
            let note = Note(context: foregroundContext)
            let string = attributedString.deformatted
            let (title, subTitle) = string.titles
            note.title = title
            note.subTitle = subTitle
            note.createdAt = Date()
            note.modifiedAt = Date()
            note.content = string
            
            foregroundContext.saveIfNeeded()
            completionHandler?(note)
        }
    }

    func increaseFetchLimit(count: Int) {
        noteFetchRequest.fetchLimit += count
    }

    func increaseTrashFetchLimit(count: Int) {
        trashFetchRequest.fetchLimit += count
    }

    // 있는 경우 갱신하고, 없는 경우 생성한다.
    func addNote(_ record: CKRecord) {
        if let note = backgroundContext.note(with: record.recordID) {
            notlify(from: record, to: note)

        } else {
            let empty = Note(context: backgroundContext)
            notlify(from: record, to: empty)
        }
        backgroundContext.saveIfNeeded()
    }

    func refreshUI() {
        foregroundContext.refreshAllObjects()

        if trashRefreshDelegate != nil {
            try? trashResultsController.performFetch()
            if let fetched = trashResultsController.fetchedObjects {
                trashRefreshDelegate.refreshUI(with: fetched.map { $0.wrapped })
            }
        } else if let fetched = mainResultsController.fetchedObjects {
            try? mainResultsController.performFetch()
            mainRefreshDelegate.refreshUI(with: fetched.map { $0.wrapped })
        }
    }

    func update(note origin: Note, with attributedText: NSAttributedString, completion: @escaping (Note) -> Void) {

        if let note = foregroundContext.object(with: origin.objectID) as? Note {
            foregroundContext.refresh(note, mergeChanges: true)
            note.content = attributedText.string
            foregroundContext.saveIfNeeded()
            refreshUI()
            completion(note)
        }
    }

    func unlockNote(_ note: Note, completion: (Note) -> Void) {
        if var content = note.content {
            content.removeCharacters(strings: [Preference.lockStr])

            modify(note: note, text: content, needUIUpdate: false, completion: completion)
        }
    }

    func lockNote(_ note: Note, completion: (Note) -> Void) {
        note.title = Preference.lockStr + (note.title ?? "")
        note.content = Preference.lockStr + (note.content ?? "")
        modify(note: note, text: note.content!, needUIUpdate: false, completion: completion)
    }

    /**
     잠금해제와 같은, 컨텐트 자체가 변화해야하는 경우에 사용되는 메서드
     중요) modifiedDate는 변화하지 않는다.
     */
    private func modify(note origin: Note,
                        text: String,
                        needUIUpdate: Bool,
                        completion: (Note) -> Void) {

        if let note = foregroundContext.object(with: origin.objectID) as? Note {
            foregroundContext.refresh(note, mergeChanges: true)
            let (title, subTitle) = text.titles
            note.title = title
            note.subTitle = subTitle
            note.content = text

            if needUIUpdate {
                note.hasEdit = true
                note.modifiedAt = Date()
            }

            foregroundContext.saveIfNeeded()
            refreshUI()
            completion(note)
        }
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

    func delete(note: Note) {
        guard note.managedObjectContext == foregroundContext else { fatalError() }
        note.isTrash = true
        foregroundContext.saveIfNeeded()
        refreshUI()
    }

    func purge(note: Note, completion: () -> Void) {
        foregroundContext.delete(note)
        foregroundContext.saveIfNeeded()
        completion()
        refreshUI()
    }

    func purgeAll() {
        trashResultsController.fetchedObjects?.forEach {
            foregroundContext.delete($0)
        }
        foregroundContext.saveIfNeeded()
        refreshUI()
    }

    func restoreAll() {
        trashResultsController.fetchedObjects?.forEach {
            $0.modifiedAt = Date()
            $0.isTrash = false
        }
        foregroundContext.saveIfNeeded()
        refreshUI()
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

        if let content = note.content {
            let titles = content.titles
            note.title = titles.0
            note.subTitle = titles.1
        }
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

private extension String {
    var titles: (String, String) {
        var strArray = self.split(separator: "\n")
        guard strArray.count != 0 else {
            return ("제목 없음".loc, "본문 없음".loc)
        }
        let titleSubstring = strArray.removeFirst()
        var titleString = String(titleSubstring)
        titleString.removeCharacters(strings: [Preference.idealistKey, Preference.firstlistKey, Preference.secondlistKey, Preference.checklistOnKey, Preference.checklistOffKey])
//        let titleLimit = 50
//        if titleString.count > titleLimit {
//            titleString = (titleString as NSString).substring(with: NSMakeRange(0, titleLimit))
//        }


        var subTitleString: String = ""
        while true {
            guard strArray.count != 0 else { break }

            let pieceSubString = strArray.removeFirst()
            var pieceString = String(pieceSubString)
            pieceString.removeCharacters(strings: [Preference.idealistKey, Preference.firstlistKey, Preference.secondlistKey, Preference.checklistOnKey, Preference.checklistOffKey])
            subTitleString.append(pieceString)
            
            if subTitleString.count > 50 {
                break
            }
            
//            let titleLimit = 50
//            if subTitleString.count > titleLimit {
//                subTitleString = (subTitleString as NSString).substring(with: NSMakeRange(0, titleLimit))
//                break
//            }
        }

        return (titleString, subTitleString.count != 0 ? subTitleString : "본문 없음".loc)
    }
}
