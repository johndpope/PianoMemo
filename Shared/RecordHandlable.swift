//
//  RecordHandlable.swift
//  Piano
//
//  Created by hoemoon on 31/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CloudKit
import CoreData

protocol RecordHandlable: class {
    var backgroundContext: NSManagedObjectContext { get }
    func createOrUpdate(record: CKRecord, isMine: Bool, completion: @escaping () -> Void)
    func remove(recordID: CKRecord.ID, completion: @escaping () -> Void)
}

extension RecordHandlable {
    func createOrUpdate(record: CKRecord, isMine: Bool, completion: @escaping () -> Void) {
        let note = Note.fetch(in: backgroundContext) { request in
            request.predicate = Note.predicateForRecordID(record.recordID)
            request.returnsObjectsAsFaults = false
            }.first
        switch note {
        case .some(let note):
            if let remoteID = note.remoteID,
                record.recordID.recordName == remoteID.recordName,
                let local = note.modifiedAt,
                let remote = record[Field.modifiedAtLocally] as? NSDate,
                (local as Date) < (remote as Date) {

                update(origin: note, record: record, isMine: isMine, completion: completion)
                completion()
            }
        case .none:
            create(record: record, isMine: isMine, completion: completion)
        }
    }

    func remove(recordID: CKRecord.ID, completion: @escaping () -> Void) {
        backgroundContext.perform {
            let note = Note.fetch(in: self.backgroundContext) { request in
                request.predicate = Note.predicateForRecordID(recordID)
                }.first
            note?.markForLocalDeletion()
            self.backgroundContext.saveOrRollback()
            completion()
        }
    }
}

extension RecordHandlable {
    private func create(record: CKRecord, isMine: Bool, completion: @escaping () -> Void) {
        backgroundContext.perform {
            let new = Note.insert(into: self.backgroundContext, needUpload: false)
            self.performUpdate(origin: new, record: record, isMine: isMine)
            self.backgroundContext.saveOrRollback()
            completion()
        }
    }

    private func update(origin: Note, record: CKRecord, isMine: Bool, completion: @escaping () -> Void) {
        backgroundContext.perform {
            self.performUpdate(origin: origin, record: record, isMine: isMine)
            self.backgroundContext.saveOrRollback()
            completion()
        }
    }

    private func performUpdate(origin: Note, record: CKRecord, isMine: Bool) {
        origin.content = record[Field.content] as? String
        origin.recordID = record.recordID

        origin.createdAt = record[Field.createdAtLocally] as? NSDate
        origin.modifiedAt = record[Field.modifiedAtLocally] as? NSDate

        // for lower version
        if origin.createdAt == nil {
            origin.createdAt = record.creationDate as NSDate?
        }
        if origin.modifiedAt == nil {
            origin.modifiedAt = record.modificationDate as NSDate?
        }
        origin.location = record[Field.location] as? CLLocation
        origin.isMine = isMine
        origin.recordArchive = record.archived as NSData

        switch record.share {
        case .some:
            origin.isShared = true
        case .none:
            origin.isShared = false
            origin.isRemoved = (record[Field.isRemoved] as? Int ?? 0) == 1 ? true : false
            // note.isLocked = (record[Field.isLocked] as? Int ?? 0) == 1 ? true : false
            origin.isPinned = (record[Field.isPinned] as? Int ?? 0) == 1 ? 1 : 0
            origin.tags = record[Field.tags] as? String

        }
    }
}

extension CloudService: RecordHandlable {}
