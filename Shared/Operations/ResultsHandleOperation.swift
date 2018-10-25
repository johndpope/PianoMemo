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
    private let backgroundContext: NSManagedObjectContext
    private let mainContext: NSManagedObjectContext

    init(operationQueue: OperationQueue,
         backgroundContext: NSManagedObjectContext,
         mainContext: NSManagedObjectContext) {

        self.queue = operationQueue
        self.mainContext = mainContext
        self.backgroundContext = backgroundContext

    }

    var resultsProvider:RequestResultsProvider? {
        if let provider = dependencies
            .filter({$0 is RequestResultsProvider})
            .first as? RequestResultsProvider {
            return provider
        }
        return nil
    }

    override func main() {
        if let provider = resultsProvider {
            if let savedRecords = provider.savedRecords {
                updateMetaData(records: savedRecords)
            } else if let ckError = provider.operationError as? CKError {
                if ckError.isSpecificErrorCode(code: .zoneNotFound) {
                    handleZoneNotFound()
                }
            } else {
                print(provider.operationError?.localizedDescription ?? "")
            }
            mainContext.saveIfNeeded()
        }
    }

    private func updateMetaData(records: [CKRecord]) {
        backgroundContext.performAndWait {
            records.forEach {
                if let note = backgroundContext.note(with: $0.recordID) {
                    note.createdBy = $0.creatorUserRecordID
                    note.modifiedBy = $0.lastModifiedUserRecordID
                    note.recordArchive = $0.archived
                    note.recordID = $0.recordID
                }
            }
            backgroundContext.saveIfNeeded()
        }
    }

    private func handleZoneNotFound() {
        guard let database = resultsProvider?.database else { return }
        let createZone = CreateZoneOperation(database: database)
        if let modifyRequest = dependencies.filter({$0 is ModifyRequestOperation})
            .first as? ModifyRequestOperation {

            let newModifyRequest = modifyRequest.reZero()
            newModifyRequest.addDependency(createZone)
            queue.addOperations([createZone, newModifyRequest], waitUntilFinished: false)
        }
    }
}
