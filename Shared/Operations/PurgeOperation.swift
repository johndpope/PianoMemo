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
    private let backgroundContext: NSManagedObjectContext
    private let mainContext: NSManagedObjectContext
    private let completion: () -> Void

    var recordsToSave: Array<RecordWrapper>? = nil
    var recordsToDelete: Array<RecordWrapper>? = nil

    init(notes: [Note]? = nil,
         recordIDs: [CKRecord.ID]? = nil,
         backgroundContext: NSManagedObjectContext,
         mainContext: NSManagedObjectContext,
         completion: @escaping () -> Void) {

        self.notes = notes
        self.recordIDs = recordIDs
        self.backgroundContext = backgroundContext
        self.mainContext = mainContext
        self.completion = completion
        super.init()
    }

    override func main() {
        backgroundContext.performAndWait {
            if let notes = notes, notes.count > 0 {
                recordsToDelete = []
                notes.forEach {
                    recordsToDelete!.append($0.recodify())
                    backgroundContext.delete($0)
                }
            }
            
            recordIDs?.forEach {
                if let note = backgroundContext.note(with: $0) {
                    backgroundContext.delete(note)
                }
            }
            backgroundContext.saveIfNeeded()
            completion()
        }
        mainContext.saveIfNeeded()
    }
}
