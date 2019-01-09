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
        if record.recordType.description == Record.note {
            backgroundContext.perform {
                let note = Note.fetch(in: self.backgroundContext) { request in
                    request.predicate = Note.predicateForRecordID(record.recordID)
                    request.returnsObjectsAsFaults = false
                    }.first
                switch note {
                case .some(let note):
                    if let local = note.modifiedAt,
                        let remote = record[NoteField.modifiedAtLocally] as? NSDate,
                        (local as Date) < (remote as Date) {

                        self.updateNote(origin: note, record: record, isMine: isMine, completion: completion)
                    }
                    completion()
                case .none:
                    self.createNote(record: record, isMine: isMine, completion: completion)
                }
            }
        } else if record.recordType.description == Record.image {
            backgroundContext.perform {
                let image = ImageAttachment.fetch(in: self.backgroundContext) { request in
                    request.predicate = ImageAttachment.predicateForRecordID(record.recordID)
                    request.returnsObjectsAsFaults = false
                    }.first

                switch image {
                case .some(let image):
                    if let local = image.modifiedAt,
                        let remote = record[ImageField.modifiedAtLocally] as? NSDate,
                        (local as Date) < (remote as Date) {

                        self.updateImage(origin: image, record: record, isMine: isMine, completion: completion)
                    }
                    completion()
                case .none:
                    self.createImage(record: record, isMine: isMine, completion: completion)
                }
            }
        }
    }

    func remove(recordID: CKRecord.ID, completion: @escaping () -> Void) {
        backgroundContext.perform {
            let note = Note.fetch(in: self.backgroundContext) { request in
                request.predicate = Note.predicateForRecordID(recordID)
                }.first
            note?.markForLocalDeletion()
            let image = ImageAttachment.fetch(in: self.backgroundContext) { request in
                request.predicate = ImageAttachment.predicateForRecordID(recordID)
                }.first
            image?.markForLocalDeletion()
            self.backgroundContext.saveOrRollback()
            completion()
        }
    }
}

extension RecordHandlable {
    private func createNote(record: CKRecord, isMine: Bool, completion: @escaping () -> Void) {
        let new = Note.insert(into: self.backgroundContext, needUpload: false)
        self.performUpdate(origin: new, record: record, isMine: isMine)
        self.backgroundContext.saveOrRollback()
        completion()

    }

    private func updateNote(origin: Note, record: CKRecord, isMine: Bool, completion: @escaping () -> Void) {
        self.performUpdate(origin: origin, record: record, isMine: isMine)
        self.backgroundContext.saveOrRollback()
        completion()
    }

    private func performUpdate(origin: Note, record: CKRecord, isMine: Bool) {
        origin.content = record[NoteField.content] as? String
        origin.recordID = record.recordID

        origin.createdAt = record[NoteField.createdAtLocally] as? NSDate
        origin.modifiedAt = record[NoteField.modifiedAtLocally] as? NSDate

        // for lower version
        if origin.createdAt == nil {
            origin.createdAt = record.creationDate as NSDate?
        }
        if origin.modifiedAt == nil {
            origin.modifiedAt = record.modificationDate as NSDate?
        }
        origin.location = record[NoteField.location] as? CLLocation
        origin.isMine = isMine
        origin.recordArchive = record.archived as NSData

        switch record.share {
        case .some:
            origin.isShared = true
        case .none:
            origin.isShared = false
            origin.isRemoved = (record[NoteField.isRemoved] as? Int ?? 0) == 1 ? true : false
            // note.isLocked = (record[Field.isLocked] as? Int ?? 0) == 1 ? true : false
            origin.isPinned = (record[NoteField.isPinned] as? Int ?? 0) == 1 ? 1 : 0
            origin.tags = record[NoteField.tags] as? String

        }
    }

    private func createImage(record: CKRecord, isMine: Bool, completion: @escaping () -> Void) {
        let new = ImageAttachment.insert(into: self.backgroundContext)
        self.performUpdate(origin: new, record: record, isMine: isMine)
        self.backgroundContext.saveOrRollback()
        completion()
    }

    private func updateImage(origin: ImageAttachment, record: CKRecord, isMine: Bool, completion: @escaping () -> Void) {
        self.performUpdate(origin: origin, record: record, isMine: isMine)
        self.backgroundContext.saveOrRollback()
        completion()
    }

    private func performUpdate(origin: ImageAttachment, record: CKRecord, isMine: Bool) {
        if let asset = record[ImageField.imageData] as? CKAsset {
            origin.imageData = NSData(contentsOf: asset.fileURL)
        }
        origin.recordID = record.recordID

        origin.createdAt = record[ImageField.createdAtLocally] as? NSDate
        origin.modifiedAt = record[ImageField.modifiedAtLocally] as? NSDate

        origin.isMine = isMine
        origin.recordArchive = record.archived as NSData
    }
}

extension CloudService: RecordHandlable {}
