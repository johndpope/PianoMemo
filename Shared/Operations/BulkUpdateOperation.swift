//
//  BulkUpdateOperation.swift
//  Piano
//
//  Created by hoemoon on 21/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

class BulkUpdateOperation: Operation, RecordProvider {
    private let backgroundContext: NSManagedObjectContext
    private let mainContext: NSManagedObjectContext
    private let completion: () -> Void
    private let request: NSFetchRequest<Note>

    var recordsToSave: Array<RecordWrapper>? = nil
    var recordsToDelete: Array<RecordWrapper>? = nil

    init(request: NSFetchRequest<Note>,
         backgroundContext: NSManagedObjectContext,
         mainContext: NSManagedObjectContext,
         completion: @escaping () -> Void) {

        self.request = request
        self.backgroundContext = backgroundContext
        self.mainContext = mainContext
        self.completion = completion
        super.init()
    }

    override func main() {
        backgroundContext.performAndWait {
            if let fetched = try? backgroundContext.fetch(request) {
                fetched.forEach { note in
                    if let object = try? backgroundContext.existingObject(with: note.objectID),
                        let note = object as? Note {
                        // update note here

//                        note.content = "fefeffefe"

                        if recordsToSave == nil {
                            recordsToSave = [note.recodify()]
                        } else {
                            recordsToSave!.append(note.recodify())
                        }
                    }
                }
            }

            backgroundContext.saveIfNeeded()
            mainContext.saveIfNeeded()

            completion()
        }
    }
}
