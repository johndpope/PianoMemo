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

typealias RecordWrapper = (Bool, CKRecord)

protocol RecordProvider{
    var recordsToSave: Array<RecordWrapper>? { get }
    var recordsToDelete: Array<RecordWrapper>? { get }
}

class CreateOperation: Operation, RecordProvider {
    let content: String
    let tags: String
    let backgroundContext: NSManagedObjectContext
    let mainContext: NSManagedObjectContext
    let completion: (() -> Void)?

    var recordsToSave: Array<RecordWrapper>? = nil
    var recordsToDelete: Array<RecordWrapper>? = nil
    
    init(content: String,
         tags: String,
         backgroundContext: NSManagedObjectContext,
         mainContext: NSManagedObjectContext,
         completion: (() -> Void)?) {

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
            let (title, subTitle) = content.titles
            note.title = title
            note.subTitle = subTitle
            note.createdAt = Date()
            note.modifiedAt = Date()
            note.content = content
            note.tags = tags
            note.isMine = true
            recordsToSave = []
            recordsToSave!.append(note.recodify())
            backgroundContext.saveIfNeeded()
        }
        mainContext.saveIfNeeded()
        completion?()
    }
}
