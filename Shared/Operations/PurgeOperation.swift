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
    private let notes: [Note]?
    private let recordIDs: [CKRecord.ID]?
    private let context: NSManagedObjectContext

    var recordsToSave: Array<RecordWrapper>? = nil
    var recordsToDelete: Array<RecordWrapper>? = nil

    init(notes: [Note]? = nil,
         recordIDs: [CKRecord.ID]? = nil,
         context: NSManagedObjectContext) {

        self.notes = notes
        self.recordIDs = recordIDs
        self.context = context
        super.init()
    }

    override func main() {
        context.performAndWait {
            if let notes = notes, notes.count > 0 {
                recordsToDelete = []
                notes.forEach {
                    recordsToDelete!.append($0.recodify())
                    context.delete($0)
                }
            }
            
            recordIDs?.forEach {
                guard let note = context.note(with: $0) else { return }
                context.delete(note)
            }
            context.saveIfNeeded()
        }
    }
}
