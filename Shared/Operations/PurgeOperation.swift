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
            mainContext.perform { [weak self] in
                guard let self = self else { return }
                self.recordsToDelete = []
                notes.forEach {
                    self.recordsToDelete!.append($0.recodify())
                    self.mainContext.delete($0)
                }
            }
        } else if let recordIDs = recordIDs {
            backgroundContext.perform { [weak self] in
                guard let self = self else { return }
                recordIDs.forEach {
                    if let note = self.backgroundContext.note(with: $0) {
                        self.backgroundContext.delete(note)
                    }
                }
                self.backgroundContext.saveIfNeeded()
                self.mainContext.saveIfNeeded()
            }
        }
        completion?()
    }
}
