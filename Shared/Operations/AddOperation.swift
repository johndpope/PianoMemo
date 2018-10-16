//
//  AddOperation.swift
//  Piano
//
//  Created by hoemoon on 10/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

class AddOperation: Operation {
    private let record: CKRecord
    private let context: NSManagedObjectContext
    private let isMine: Bool

    private(set) var note: Note?

    init(_ record: CKRecord, context: NSManagedObjectContext, isMine: Bool) {
        self.record = record
        self.context = context
        self.isMine = isMine
    }

    override func main() {
        if let note = context.note(with: record.recordID) {
            notlify(from: record, to: note)
        } else {
            let empty = Note(context: context)
            notlify(from: record, to: empty)
        }
    }

    private func notlify(from record: CKRecord, to note: Note) {
        typealias Field = RemoteStorageSerevice.NoteFields
        context.performAndWait {
            // update custom fields
            note.content = record[Field.content] as? String
            note.recordID = record.recordID

            note.createdBy = record.creatorUserRecordID
            note.modifiedBy = record.lastModifiedUserRecordID
            if note.createdAt == nil {
                note.createdAt = record.creationDate
            }
            if note.modifiedAt == nil {
                note.modifiedAt = record.modificationDate
            }
            note.location = record[Field.location] as? CLLocation
            note.isMine = isMine
            note.recordArchive = record.archived
            if let content = note.content {
                let titles = content.titles
                note.title = titles.0
                note.subTitle = titles.1
            }
            
            if let _ = record.share {
                note.isShared = true
            } else {
                note.isShared = false
                note.isRemoved = (record[Field.isRemoved] as? Int ?? 0) == 1 ? true : false
                note.isLocked = (record[Field.isLocked] as? Int ?? 0) == 1 ? true : false
                note.tags = record[Field.tags] as? String
            }
            self.note = note
            context.saveIfNeeded()
        }
    }
}
