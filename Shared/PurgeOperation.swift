//
//  PurgeOperation.swift
//  Piano
//
//  Created by hoemoon on 09/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

class PurgeOperation: Operation, RecordProvider {
    private let note: Note?
    private let recordID: CKRecord.ID?
    private let context: NSManagedObjectContext

    var recordsToSave: Array<CKRecord>?
    var recordsToDelete: Array<CKRecord>?

    init(note: Note? = nil,
         recordID: CKRecord.ID? = nil,
         context: NSManagedObjectContext) {

        self.note = note
        self.recordID = recordID
        self.context = context
        super.init()
    }

    override func main() {
        if let note = note {
            context.performAndWait {
                context.delete(note)
            }
            recordsToDelete = [note.recodify()]
        } else if let recordID = recordID,
            let note = context.note(with: recordID) {
            context.performAndWait {
                context.delete(note)
            }
        }
        context.saveIfNeeded()
    }
}
