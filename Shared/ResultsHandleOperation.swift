//
//  ResultsHandleOperation.swift
//  Piano
//
//  Created by hoemoon on 10/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

class ResultsHandleOperation: Operation {
    private let queue: OperationQueue
    private let context: NSManagedObjectContext

    init(operationQueue: OperationQueue, context: NSManagedObjectContext) {
        self.queue = operationQueue
        self.context = context
    }

    override func main() {
        if let resultsProvider = dependencies
            .filter({$0 is RequestResultsProvider})
            .first as? RequestResultsProvider {

            if let ckError = resultsProvider.operationError as? CKError {
                if ckError.isSpecificErrorCode(code: .zoneNotFound) {
                    
                }
            } else if let savedRecords = resultsProvider.savedRecords {
                updateMetaData(records: savedRecords)
            }
        }
        print(#function)
    }

    private func updateMetaData(records: [CKRecord]) {
        context.performAndWait {
            for record in records {
                if let note = context.note(with: record.recordID) {
                    note.createdAt = record.creationDate
                    note.createdBy = record.creatorUserRecordID
                    note.modifiedAt = record.modificationDate
                    note.modifiedBy = record.lastModifiedUserRecordID
                    note.recordArchive = record.archived
                    note.recordID = record.recordID
                }
            }
            do {
                try context.save()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

private extension NSManagedObjectContext {
    func note(with recordID: CKRecord.ID) -> Note? {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
        request.predicate = NSPredicate(format: "%K == %@", "recordID", recordID as CVarArg)
        request.fetchLimit = 1
        request.sortDescriptors = [sort]
        if let fetched = try? fetch(request), let note = fetched.first {
            return note
        }
        return nil
    }
}

private extension CKRecord {
    var archived: Data {
        let data = NSMutableData()
        let coder = NSKeyedArchiver(forWritingWith: data)
        coder.requiresSecureCoding = true
        self.encodeSystemFields(with: coder)
        coder.finishEncoding()
        return Data(referencing: data)
    }
}

