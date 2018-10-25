//
//  RemoteStorageService.swift
//  Piano
//
//  Created by hoemoon on 26/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit

/// 원격 저장소에 접근하는 모든 인터페이스 제공

typealias PreparationHandler = ((CKShare?, CKContainer?, Error?) -> Void)
typealias RemoteStorageProvider = CloudDatabaseProvider & FetchRequestProvider & ShareManageDelegate
typealias PermissionComletion = (CKContainer_Application_PermissionStatus, Error?) -> Void

protocol CloudDatabaseProvider: class {
    var container: CKContainer { get }
    var privateDatabase: CKDatabase { get }
    var sharedDatabase: CKDatabase { get }
}

protocol ShareManageDelegate {
    func acceptShare(metadata: CKShare.Metadata, completion: @escaping () -> Void)
    func requestShare(
        recordToShare: CKRecord,
        preparationHandler: @escaping PreparationHandler
    )
    func requestApplicationPermission(completion: @escaping PermissionComletion)
    func requestFetchRecords(
        by recordIDs: [CKRecord.ID],
        isMine: Bool,
        completion: @escaping ([CKRecord.ID : CKRecord]?, Error?) -> Void
    )
    func requestAddFetchedRecords(
        by recordIDs: [CKRecord.ID],
        isMine: Bool,
        completion: @escaping () -> Void
    )
}

protocol FetchRequestProvider: class {
    var syncController: Synchronizable! { get set }
    func setup()
    func fetchChanges(in scope: CKDatabase.Scope, needByPass: Bool, completion: @escaping () -> Void)
}

class RemoteStorageSerevice: CloudDatabaseProvider & FetchRequestProvider {
    weak var syncController: Synchronizable!

    lazy var container = CKContainer.default()
    lazy var privateDatabase = container.privateCloudDatabase
    lazy var sharedDatabase = container.sharedCloudDatabase

    private lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    private enum SubscriptionID {
        static let privateChange = "privateChange"
        static let sharedChange = "sharedChange"
    }

    enum Records {
        static let note = "Note"
    }

    enum NoteFields {
        // CUSTOM FIELD
        static let content = "content"
        static let isRemoved = "isRemoved"
        static let location = "location"
        static let recordID = "recordID"
        static let isLocked = "isLocked"
        static let tags = "tags"

        // SYSTEM FIELD
        static let createdBy = "createdBy"
        static let modifiedBy = "modifiedBy"
    }

    func setup() {
        addDatabaseSubscription() {}
        let requestUserID = RequestUserIDOperation(container: container)
        queue.addOperation(requestUserID)
    }

    func fetchChanges(
        in scope: CKDatabase.Scope,
        needByPass: Bool = false,
        completion: @escaping () -> Void) {

        func enqueue(database: CKDatabase) {
            let fetchDatabaseChange = FetchDatabaseChangeOperation(database: database)
            let fetchZoneChange = FetchZoneChangeOperation(
                database: database
            )
            let handlerZoneChange = HandleZoneChangeOperation(
                context: syncController.backgroundContext,
                needByPass: needByPass
            )
            let completionOperation = BlockOperation(block: completion)
            let delayed = BlockOperation { [weak self] in
                self?.syncController.processDelayedTasks()
            }
            fetchZoneChange.addDependency(fetchDatabaseChange)
            handlerZoneChange.addDependency(fetchZoneChange)
            completionOperation.addDependency(handlerZoneChange)
            delayed.addDependency(completionOperation)

            self.queue.addOperations(
                [fetchDatabaseChange, fetchZoneChange, handlerZoneChange, completionOperation, delayed],
                waitUntilFinished: false
            )
        }
        switch scope {
        case .private:
            enqueue(database: privateDatabase)
        case .shared:
            enqueue(database: sharedDatabase)
        case .public:
            fatalError()
        }
    }
}

extension RemoteStorageSerevice: ShareManageDelegate {
    func requestShare(
        recordToShare: CKRecord,
        preparationHandler: @escaping PreparationHandler) {

        let operation = CKModifyRecordsOperation()
        let ckShare = CKShare(rootRecord: recordToShare)
        operation.recordsToSave = [recordToShare, ckShare]
        operation.modifyRecordsCompletionBlock = {
            [weak self] _, _, operationError in
            if operationError == nil {
                preparationHandler(ckShare, self?.container, operationError)
            } else {
                preparationHandler(nil, nil, operationError)
            }
        }
        privateDatabase.add(operation)
    }

    func acceptShare(
        metadata: CKShare.Metadata,
        completion: @escaping () -> Void) {

        let operation = CKAcceptSharesOperation(shareMetadatas: [metadata])
        operation.perShareCompletionBlock = {
            metadata, share, error in
            // 1
            OperationQueue.main.addOperation {
                completion()
            }
        }
        operation.acceptSharesCompletionBlock = {
            error in
        }
        container.add(operation)
    }

    func requestFetchRecords(
        by recordIDs: [CKRecord.ID],
        isMine: Bool,
        completion: @escaping ([CKRecord.ID : CKRecord]?, Error?) -> Void) {

        let operation = CKFetchRecordsOperation(recordIDs: recordIDs)
        operation.fetchRecordsCompletionBlock = {
            recordsByRecordID, operationError in
            OperationQueue.main.addOperation {
                completion(recordsByRecordID, operationError)
            }
        }
        if isMine {
            privateDatabase.add(operation)
        } else {
            sharedDatabase.add(operation)
        }
    }

    func requestAddFetchedRecords(
        by recordIDs: [CKRecord.ID],
        isMine: Bool,
        completion: @escaping () -> Void) {

        let database = isMine ? privateDatabase : sharedDatabase

        let fetch = FetchRecordsOperation(database: database, recordIDs: recordIDs)
        let handler = HandleZoneChangeOperation(context: syncController.backgroundContext)
        let block = BlockOperation(block: completion)

        handler.addDependency(fetch)
        block.addDependency(handler)

        queue.addOperations([fetch, handler, block], waitUntilFinished: false)
    }

    func requestApplicationPermission(
        completion: @escaping PermissionComletion) {

        container.requestApplicationPermission(.userDiscoverability) {
            applicationPermissionStatus, error in
            completion(applicationPermissionStatus, error)
        }
    }
}

extension RemoteStorageSerevice {
    private func addDatabaseSubscription(completion: @escaping () -> Void) {
        func fetchBoth() {
            self.fetchChanges(in: .private) { }
            self.fetchChanges(in: .shared) { }
        }
        if !UserDefaults.standard.bool(forKey: "createdCustomZone") {
            let createZone = CreateZoneOperation(database: privateDatabase)
            let block = BlockOperation {
                fetchBoth()
            }
            block.addDependency(createZone)
            queue.addOperations([createZone, block], waitUntilFinished: false)
        } else {
            fetchBoth()
        }

        if !UserDefaults.standard.bool(forKey: "subscribedToPrivateChanges") {
            let databaseSubscriptionOperation = createDatabaseSubscriptionOperation(with: SubscriptionID.privateChange)
            databaseSubscriptionOperation.modifySubscriptionsCompletionBlock = {
                subscriptions, iDs, error in
                if error == nil {
                    UserDefaults.standard.set(true, forKey: "subscribedToPrivateChanges")
                } else if let ckError = error as? CKError, ckError.isSpecificErrorCode(code: .partialFailure) {
                    UserDefaults.standard.set(true, forKey: "subscribedToPrivateChanges")
                }
            }
            privateDatabase.add(databaseSubscriptionOperation)
        }
        if !UserDefaults.standard.bool(forKey: "subscribedToSharedChanges") {
            let databaseSubscriptionOperation = createDatabaseSubscriptionOperation(with: SubscriptionID.sharedChange)
            databaseSubscriptionOperation.modifySubscriptionsCompletionBlock = {
                subscriptions, iDs, error in
                if error == nil {
                    UserDefaults.standard.set(true, forKey: "subscribedToSharedChanges")
                } else if let ckError = error as? CKError, ckError.isSpecificErrorCode(code: .partialFailure) {
                    UserDefaults.standard.set(true, forKey: "subscribedToSharedChanges")
                }
            }
            sharedDatabase.add(databaseSubscriptionOperation)
        }
    }

    private func createDatabaseSubscriptionOperation(with subscriptionID: String) -> CKModifySubscriptionsOperation {
        let subscription = CKDatabaseSubscription(subscriptionID: subscriptionID)
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info
        let operation = CKModifySubscriptionsOperation(
            subscriptionsToSave: [subscription],
            subscriptionIDsToDelete: nil
        )
        return operation
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
                let clientContent = client[NoteFields.content] as? String {

                if serverModifiedAt > clientMotifiedAt {
                    return server
                } else {
                    server[NoteFields.content] = clientContent
                    return server
                }
            }
            return server

        } else {
            return nil
        }
    }
}
