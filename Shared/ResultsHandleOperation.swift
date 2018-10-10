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
    }

    private func updateMetaData(records: [CKRecord]) {
        context.performAndWait {
            records.forEach {
                if let note = context.note(with: $0.recordID) {
                    note.createdAt = $0.creationDate
                    note.createdBy = $0.creatorUserRecordID
                    note.modifiedAt = $0.modificationDate
                    note.modifiedBy = $0.lastModifiedUserRecordID
                    note.recordArchive = $0.archived
                    note.recordID = $0.recordID
                }
            }
            context.saveIfNeeded()
        }
    }
}
