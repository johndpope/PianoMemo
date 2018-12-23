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

    var resultsProvider: RequestResultsProvider? {
        if let provider = dependencies
            .filter({$0 is RequestResultsProvider})
            .first as? RequestResultsProvider {
            return provider
        }
        return nil
    }

    var beforeModifyOperation: ModifyRequestOperation? {
        if let modify = dependencies
            .filter({$0 is ModifyRequestOperation})
            .first as? ModifyRequestOperation {
            return modify
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
                } else if ckError.isSpecificErrorCode(code: .serverRecordChanged) {
                    handleServerRecordChanged(ckError: ckError)
                }
            } else {
                print(provider.operationError?.localizedDescription ?? "")
            }
        }
    }

    private func updateMetaData(records: [CKRecord]) {
        backgroundContext.performAndWait {
            records.forEach {
                if let note = backgroundContext.note(with: $0.recordID) {
                    note.recordArchive = $0.archived
                    note.recordID = $0.recordID
                }
            }
            backgroundContext.saveIfNeeded()
            mainContext.saveIfNeeded()
        }
    }

    private func handleZoneNotFound() {
        guard let database = resultsProvider?.database else { return }
        let createZone = CreateZoneOperation(database: database)
        if let modifyRequest = dependencies.filter({$0 is ModifyRequestOperation})
            .first as? ModifyRequestOperation {

            let newModifyRequest = modifyRequest.remakeOperation()
            let resultsHandler = ResultsHandleOperation(
                operationQueue: self.queue,
                backgroundContext: backgroundContext,
                mainContext: mainContext
            )
            newModifyRequest.addDependency(createZone)
            newModifyRequest.addDependency(resultsHandler)
            queue.addOperations([createZone, newModifyRequest, resultsHandler], waitUntilFinished: false)
        }
    }

    private func handleServerRecordChanged(ckError: CKError) {
        guard let before = beforeModifyOperation,
            let recordsTosave = before.recordsToSave,
            let thatRecord = recordsTosave.first else { return }

        if let resolved = resolve(error: ckError) {
            let newModifyRequest = before.remakeOperation(resolved: (thatRecord.0, resolved))
            let resultsHandler = ResultsHandleOperation(
                operationQueue: self.queue,
                backgroundContext: backgroundContext,
                mainContext: mainContext
            )
            resultsHandler.addDependency(newModifyRequest)
            queue.addOperations([newModifyRequest, resultsHandler], waitUntilFinished: false)
        }
    }

    private func resolve(error: CKError) -> CKRecord? {
        let records = error.getMergeRecords()
        if let ancestorRecord = records.0,
            let clientRecord = records.1,
            let serverRecord = records.2 {

            return Resolver.merge(
                ancestor: ancestorRecord,
                client: clientRecord,
                server: serverRecord
            )
        } else if let server = records.2, let client = records.1 {
            if let serverModifiedAt = server.modificationDate,
                let clientMotifiedAt = client.modificationDate,
                let clientContent = client[Field.content] as? String {

                if serverModifiedAt > clientMotifiedAt {
                    return server
                } else {
                    server[Field.content] = clientContent
                    return server
                }
            }
            return server
        } else {
            return nil
        }
    }
}
