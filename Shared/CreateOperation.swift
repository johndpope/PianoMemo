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
    let string: String
    let context: NSManagedObjectContext

    var recordsToSave: Array<RecordWrapper>?
    var recordsToDelete: Array<RecordWrapper>?

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
            note.isMine = true
            recordsToSave = [note.recodify()]
            context.saveIfNeeded()
        }
    }
}
