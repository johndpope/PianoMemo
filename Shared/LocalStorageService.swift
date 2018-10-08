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
    func refreshUI(with target: [NoteWrapper], completion: @escaping () -> Void)
}

/// 로컬 저장소 상태를 변화시키는 모든 인터페이스 제공

protocol LocalStorageServiceDelegate: class {
    var foregroundContext: NSManagedObjectContext { get }
    var mainResultsController: NSFetchedResultsController<Note> { get }
    var mainRefreshDelegate: UIRefreshDelegate! { get set }
    var trashRefreshDelegate: UIRefreshDelegate! { get set }
    var trashResultsController: NSFetchedResultsController<Note> { get }

    func add(_ record: CKRecord)
    func increaseFetchLimit(count: Int)
    func create(with attributedString: NSAttributedString)
    func fetch(with keyword: String, completionHandler: @escaping ([Note]) -> Void)
    func refreshUI(completion: @escaping () -> Void)
    func update(note origin: Note, with attributedText: NSAttributedString)
    func purge(note: Note, completion: @escaping () -> Void)
    func purgeAll()
    func restoreAll()
    func increaseTrashFetchLimit(count: Int)
    func setup()
    func delete(note: Note)
    func unlockNote(_ note: Note, completion: @escaping () -> Void)
    func lockNote(_ note: Note, completion: @escaping () -> Void)
    func purge(recordID: CKRecord.ID)
    func restore(note: Note, completion: @escaping () -> Void)
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
        updateOwnerInfo()
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

        if let insertsOrUpdates = insertsOrUpdates {
            let passedNotes = insertsOrUpdates.compactMap {
                backgroundContext.object(with: $0.objectID) as? Note
            }
            let records = passedNotes.map { $0.recodify() }
            backgroundContext.saveIfNeeded()

            remoteStorageServiceDelegate
                .requestModify(recordsToSave: records, recordsToDelete: nil) {
                    [weak self] saves, _, error in
                    guard let self = self else { return }
                    if let saves = saves, error == nil {
                        self.updateMetaData(records: saves) {
                            self.backgroundContext.saveIfNeeded()
                            self.refreshUI { }
                        }
                    } else if let error = error {
                        // TODO: 네트워크 문제로 지우지 못한 녀석들은 나중에 따로 처리해야 함
                        // 해당 오류를 잡아서 처리해야 함.
                        print(error)
                    }
            }
        } else if let deletes = deletes {
            let records = Array(deletes).map { $0.recodify() }
            remoteStorageServiceDelegate
                .requestModify(recordsToSave: nil, recordsToDelete: records) {
                    _, _, error in
                    // TODO: 네트워크 문제로 지우지 못한 녀석들은 나중에 따로 처리해야 함
                    // 해당 오류를 잡아서 처리해야 함.
                    if error == nil {

                    } else if let error = error {
                        print(error)
                        fatalError()
                    }
            }
        }
    }

    private func updateMetaData(records: [CKRecord], completion: () -> Void) {
        for record in records {
            if let note = backgroundContext.note(with: record.recordID) {
                note.createdAt = record.creationDate
                note.createdBy = record.creatorUserRecordID
                note.modifiedAt = record.modificationDate
                note.modifiedBy = record.lastModifiedUserRecordID
                note.recordArchive = record.archived
                note.recordID = record.recordID
            }
        }
        completion()
    }

    private func updateOwnerInfo() {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
        let predicates = [
            NSPredicate(format: "createdBy != nil"),
            NSPredicate(format: "ownerID == nil")
        ]
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [sort]

        if let fetched = try? backgroundContext.fetch(request) {
            guard fetched.count > 0 else { return }
            for note in fetched {
                if let recordID = note.createdBy as? CKRecord.ID {
                    remoteStorageServiceDelegate
                        .requestUserIdentity(userRecordID: recordID) {
                            [weak self] identity, error in
                            guard let self = self else { return }
                            if error == nil {
                                note.ownerID = identity
                                self.backgroundContext.saveIfNeeded()
                            }
                    }
                }
            }
        }
    }

    func fetch(with keyword: String, completionHandler: @escaping ([Note]) -> Void) {
        let fetchOperation = FetchNoteOperation(controller: mainResultsController) { notes in
            completionHandler(notes)
        }
        fetchOperation.setRequest(with: keyword)
        if fetchOperationQueue.operationCount > 0 {
            fetchOperationQueue.cancelAllOperations()
        }
        fetchOperationQueue.addOperation(fetchOperation)
    }

    func create(with attributedString: NSAttributedString) {
        
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
            refreshUI { }
        }
    }

    func increaseFetchLimit(count: Int) {
        noteFetchRequest.fetchLimit += count
    }

    func increaseTrashFetchLimit(count: Int) {
        trashFetchRequest.fetchLimit += count
    }

    // 있는 경우 갱신하고, 없는 경우 생성한다.
    func add(_ record: CKRecord) {
        if let note = backgroundContext.note(with: record.recordID) {
            notlify(from: record, to: note)
        } else {
            let empty = Note(context: backgroundContext)
            notlify(from: record, to: empty)
        }
        
        backgroundContext.saveIfNeeded()
    }

    func refreshUI(completion: @escaping () -> Void) {
        foregroundContext.refreshAllObjects()

        if trashRefreshDelegate != nil {
            try? trashResultsController.performFetch()
            if let fetched = trashResultsController.fetchedObjects, fetched.count > 0 {
                trashRefreshDelegate.refreshUI(with: fetched.map { $0.wrapped }, completion: completion)
            }
        }

        if mainRefreshDelegate != nil {
            try? mainResultsController.performFetch()
            if let fetched = mainResultsController.fetchedObjects, fetched.count > 0 {
                mainRefreshDelegate.refreshUI(with: fetched.map { $0.wrapped }, completion: completion)
            }
        }
    }

    func update(note origin: Note, with attributedText: NSAttributedString) {
//        if let note = foregroundContext.object(with: origin.objectID) as? Note {
//            foregroundContext.refresh(note, mergeChanges: true)
//            note.content = attributedText.string
//
//            refreshUI { [weak self] in
//                try? self?.foregroundContext.save()
//            }
//        }

        var range = NSMakeRange(0, 0)
        let mutableAttrString = NSMutableAttributedString(attributedString: attributedText)

        while true {
            guard range.location < mutableAttrString.length else { break }
            let paraRange = (mutableAttrString.string as NSString).paragraphRange(for: range)
            range.location = paraRange.location + paraRange.length + 1

            guard let bulletValue = BulletValue(text: mutableAttrString.string, selectedRange: paraRange)
                else { continue }

            mutableAttrString.replaceCharacters(in: bulletValue.range, with: bulletValue.key)
        }

        let str = mutableAttrString.string
        let (title, subTitle) = str.titles

        origin.title = title
        origin.subTitle = subTitle
        origin.content = str
        origin.modifiedAt = Date()
        origin.hasEdit = false

        refreshUI { [weak self] in
            self?.foregroundContext.saveIfNeeded()
        }
    }

    func unlockNote(_ note: Note, completion: @escaping () -> Void) {
        if var content = note.content {
            content.removeCharacters(strings: [Preference.lockStr])

            modify(note: note, text: content, needUIUpdate: false, completion: completion)
        }
    }

    func lockNote(_ note: Note, completion: @escaping () -> Void) {
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
                        completion: @escaping () -> Void) {

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

            refreshUI { [weak self] in
                self?.foregroundContext.saveIfNeeded()
                completion()
            }
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
        foregroundContext.performAndWait {
            note.isTrash = true
            note.modifiedAt = Date()
        }
        refreshUI { [weak self] in
            self?.foregroundContext.saveIfNeeded()
        }
    }

    func restore(note: Note, completion: @escaping () -> Void) {
        foregroundContext.performAndWait {
            note.isTrash = false
            note.modifiedAt = Date()
        }
        refreshUI { [weak self] in
            self?.foregroundContext.saveIfNeeded()
            completion()
        }
    }

    func purge(note: Note, completion: @escaping () -> Void) {
        foregroundContext.delete(note)
        refreshUI { [weak self] in
            self?.foregroundContext.saveIfNeeded()
            completion()
        }
    }

    func purge(recordID: CKRecord.ID) {
        if let note = backgroundContext.note(with: recordID) {
            backgroundContext.delete(note)
            backgroundContext.saveIfNeeded()
            refreshUI {}
        }
    }

    func purgeAll() {
        trashResultsController.fetchedObjects?.forEach {
            foregroundContext.delete($0)
        }
        refreshUI { [weak self] in
            self?.foregroundContext.saveIfNeeded()
        }
    }

    func restoreAll() {
        trashResultsController.fetchedObjects?.forEach {
            $0.modifiedAt = Date()
            $0.isTrash = false
        }
        refreshUI { [weak self] in
            self?.foregroundContext.saveIfNeeded()
        }
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
