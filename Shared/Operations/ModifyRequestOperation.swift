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
    var database: CKDatabase? { get }
}

//class ModifyRequestOperation: AsyncOperation, RequestResultsProvider {
//    let privateDatabase: CKDatabase
//    let sharedDatabase: CKDatabase
//
//    var recordsToSave: Array<RecordWrapper>?
//    var recordsToDelete: Array<RecordWrapper>?
//
//    var savedRecords: [CKRecord]?
//    var deletedRecordIDs: [CKRecord.ID]?
//    var operationError: Error?
//    var database: CKDatabase?
//
//    init(privateDatabase: CKDatabase, sharedDatabase: CKDatabase) {
//        self.privateDatabase = privateDatabase
//        self.sharedDatabase = sharedDatabase
//    }
//
//    override func main() {
//        if let recordProvider = dependencies
//            .filter({ $0 is RecordProvider })
//            .first as? RecordProvider {
//
//            self.recordsToSave = recordProvider.recordsToSave
//            self.recordsToDelete = recordProvider.recordsToDelete
//        }
//        let operation = CKModifyRecordsOperation()
//        operation.savePolicy = .ifServerRecordUnchanged
//        operation.qualityOfService = .userInitiated
//        operation.modifyRecordsCompletionBlock = {
//            [weak self] savedRecords, deletedRecordIDs, operationError in
//            guard let `self` = self else { return }
//            self.savedRecords = savedRecords
//            self.deletedRecordIDs = deletedRecordIDs
//            self.operationError = operationError
//            self.state = .Finished
//        }
//
//        if let recordsToSave = recordsToSave {
//            let shared = recordsToSave.filter { $0.0 == false }.map { $0.1 }
//            let privateRecords = recordsToSave.filter { $0.0 == true }.map { $0.1 }
//            if shared.count > 0 {
//                operation.recordsToSave = shared
//                sharedDatabase.add(operation)
//                database = sharedDatabase
//            } else {
//                operation.recordsToSave = privateRecords
//                privateDatabase.add(operation)
//                database = privateDatabase
//            }
//
//        } else if let recordsToDelete = recordsToDelete {
//            let shared = recordsToDelete.filter { $0.0 == false }.map { $0.1 }
//            let privateRecords = recordsToDelete.filter { $0.0 == true }.map { $0.1 }
//            if shared.count > 0 {
//                operation.recordIDsToDelete = shared.map { $0.recordID }
//                sharedDatabase.add(operation)
//                database = sharedDatabase
//            } else {
//                operation.recordIDsToDelete = privateRecords.map { $0.recordID }
//                privateDatabase.add(operation)
//                database = privateDatabase
//            }
//        }
//    }
//
//    func remakeOperation() -> ModifyRequestOperation {
//        let operation = ModifyRequestOperation(privateDatabase: privateDatabase, sharedDatabase: sharedDatabase)
//        operation.recordsToSave = self.recordsToSave
//        operation.recordsToDelete = self.recordsToDelete
//        return operation
//    }
//
//    func remakeOperation(resolved: RecordWrapper) -> ModifyRequestOperation {
//        let operation = ModifyRequestOperation(privateDatabase: privateDatabase, sharedDatabase: sharedDatabase)
//        operation.recordsToSave = [resolved]
//
//        return operation
//    }
//}
