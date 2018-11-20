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
    private let completion: (() -> Void)?

    var recordsToSave: Array<RecordWrapper>? = nil
    var recordsToDelete: Array<RecordWrapper>? = nil

    init(notes: [Note]? = nil,
         recordIDs: [CKRecord.ID]? = nil,
         backgroundContext: NSManagedObjectContext,
         mainContext: NSManagedObjectContext,
         completion: (() -> Void)?) {

        self.notes = notes
        self.recordIDs = recordIDs
        self.backgroundContext = backgroundContext
        self.mainContext = mainContext
        self.completion = completion
        super.init()
    }

    override func main() {
        if let notes = notes, notes.count > 0 {
            backgroundContext.performAndWait {
                recordsToDelete = []
                notes.forEach {
                    if let object = try? backgroundContext.existingObject(with: $0.objectID),
                        let note = object as? Note {
                        print(note, "eeeeeeeeeee")
                        backgroundContext.delete(note)
                        recordsToDelete!.append(note.recodify())
                    }
                }
                mainContext.saveIfNeeded()
            }
        } else if let recordIDs = recordIDs {
            backgroundContext.performAndWait {
                recordIDs.forEach {
                    if let note = self.backgroundContext.note(with: $0) {
                        self.backgroundContext.delete(note)
                    }
                }
                backgroundContext.saveIfNeeded()
                mainContext.saveIfNeeded()
            }
        }
        completion?()
    }
}
