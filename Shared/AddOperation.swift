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
            note.content = record[Field.content] as? String
            note.isRemoved = (record[Field.isRemoved] as? Int ?? 0) == 1 ? true : false
            note.location = record[Field.location] as? CLLocation
            note.recordID = record.recordID

            note.createdAt = record.creationDate
            note.createdBy = record.creatorUserRecordID
            note.modifiedAt = record.modificationDate
            note.modifiedBy = record.lastModifiedUserRecordID

            note.isMine = isMine
            note.recordArchive = record.archived
            if let content = note.content {
                let titles = content.titles
                note.title = titles.0
                note.subTitle = titles.1
            }
            context.saveIfNeeded()
        }
    }
}
