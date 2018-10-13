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
    let context: NSManagedObjectContext

    var recordsToSave: Array<RecordWrapper>? = nil
    var recordsToDelete: Array<RecordWrapper>? = nil
    
    init(content: String, tags: String, context: NSManagedObjectContext) {
        self.content = content
        self.tags = tags
        self.context = context
        super.init()
    }

    override func main() {
        context.performAndWait {
            let note = Note(context: context)
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
            context.saveIfNeeded()
        }
    }
}
