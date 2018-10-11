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

protocol RecordProvider{
    var recordsToSave: Array<CKRecord>? { get }
    var recordsToDelete: Array<CKRecord>? { get }
}

class CreateOperation: Operation, RecordProvider {
    let string: String
    let context: NSManagedObjectContext

    var recordsToSave: Array<CKRecord>?
    var recordsToDelete: Array<CKRecord>?

    init(string: String,
         context: NSManagedObjectContext) {
        self.string = string
        self.context = context
        super.init()
    }

    override func main() {
        context.performAndWait {
            let note = Note(context: context)
            let (title, subTitle) = string.titles
            note.title = title
            note.subTitle = subTitle
            note.createdAt = Date()
            note.modifiedAt = Date()
            note.content = string
            recordsToSave = [note.recodify()]
            context.saveIfNeeded()
        }
    }
}
