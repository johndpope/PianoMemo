//
//  PurgeOperation.swift
//  Piano
//
//  Created by hoemoon on 09/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit

class PurgeOperation: Operation, RecordProvider {
    private let note: Note
    var recordsToSave: Array<CKRecord>?
    var recordsToDelete: Array<CKRecord>?

    init(note: Note) {
        self.note = note
        super.init()
    }

    override func main() {
        guard let context = note.managedObjectContext else { return }
        context.performAndWait {
            context.delete(note)
        }
        recordsToDelete = [note.recodify()]

        do {
            try context.save()
        } catch {
            print(error)
        }
    }
}
