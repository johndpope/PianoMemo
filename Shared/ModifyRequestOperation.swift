//
//  ModifyRequestOperation.swift
//  Piano
//
//  Created by hoemoon on 10/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit

protocol RequestResultsProvider {
    var savedRecords: [CKRecord]? { get }
    var deletedRecordIDs: [CKRecord.ID]? { get }
    var operationError: Error? { get }
}

class ModifyRequestOperation: AsyncOperation, RequestResultsProvider {
    let privateDatabase: CKDatabase
    let sharedDatabase: CKDatabase

    private var recordsToSave: Array<CKRecord>?
    private var recordsToDelete: Array<CKRecord>?

    var savedRecords: [CKRecord]?
    var deletedRecordIDs: [CKRecord.ID]?
    var operationError: Error?

    init(privateDatabase: CKDatabase, sharedDatabase: CKDatabase) {
        self.privateDatabase = privateDatabase
        self.sharedDatabase = sharedDatabase
    }

    override func main() {
        if let recordProvider = dependencies
            .filter({ $0 is RecordProvider })
            .first as? RecordProvider {

            self.recordsToSave = recordProvider.recordsToSave
            self.recordsToDelete = recordProvider.recordsToDelete
        }
        let operation = CKModifyRecordsOperation()
        operation.savePolicy = .ifServerRecordUnchanged
        operation.qualityOfService = .userInitiated
        operation.modifyRecordsCompletionBlock = {
            [weak self] savedRecords, deletedRecordIDs, operationError in
            guard let `self` = self else { return }
            self.savedRecords = savedRecords
            self.deletedRecordIDs = deletedRecordIDs
            self.operationError = operationError
            self.state = .Finished
        }

        if let recordsToSave = recordsToSave {
            let shared = recordsToSave.filter { $0.isShared }
            let privateRecords = recordsToSave.filter { !$0.isShared }
            if shared.count > 0 {
                operation.recordsToSave = shared
                sharedDatabase.add(operation)
            } else {
                operation.recordsToSave = privateRecords
                privateDatabase.add(operation)
            }

        } else if let recordsToDelete = recordsToDelete {
            let shared = recordsToDelete.filter { $0.isShared }
            let privateRecords = recordsToDelete.filter { !$0.isShared }
            if shared.count > 0 {
                operation.recordIDsToDelete = shared.map { $0.recordID }
                sharedDatabase.add(operation)
            } else {
                operation.recordIDsToDelete = privateRecords.map { $0.recordID }
                privateDatabase.add(operation)
            }
        }
    }
}
