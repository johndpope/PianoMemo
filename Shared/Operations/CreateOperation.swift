//
//  CreateOperation.swift
//  Piano
//
//  Created by hoemoon on 09/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

protocol RecordProvider {
    var recordsToSave: Array<RecordWrapper>? { get }
    var recordsToDelete: Array<RecordWrapper>? { get }
}

class CreateOperation: Operation, RecordProvider {
    let content: String
    let tags: String
    let backgroundContext: NSManagedObjectContext
    let mainContext: NSManagedObjectContext
    let completion: ((Note) -> Void)?

    var recordsToSave: Array<RecordWrapper>?
    var recordsToDelete: Array<RecordWrapper>?

    init(content: String,
         tags: String,
         backgroundContext: NSManagedObjectContext,
         mainContext: NSManagedObjectContext,
         completion: ((Note) -> Void)?) {

        self.content = content
        self.tags = tags
        self.backgroundContext = backgroundContext
        self.mainContext = mainContext
        self.completion = completion
        super.init()
    }

    override func main() {
        backgroundContext.performAndWait {
            let note = Note(context: backgroundContext)
            note.createdAt = Date() as NSDate
            note.modifiedAt = Date() as NSDate
            note.content = content
            note.tags = tags
            note.isMine = true
            recordsToSave = []
            recordsToSave!.append(note.recodify())
            backgroundContext.saveIfNeeded()
            DispatchQueue.main.async { [weak self] in
                self?.completion?(note)
            }
            mainContext.saveIfNeeded()
        }
    }
}
