//
//  CloudKitService.swift
//  Piano
//
//  Created by hoemoon on 22/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CloudKit
import CoreData

typealias ModifyCompletion = (([CKRecord]?, [CKRecord.ID]?, Error?) -> Void)?
typealias Record = CloudService.Record
typealias Field = CloudService.Field
typealias PreparationHandler = ((CKShare?, CKContainer?, Error?) -> Void)
typealias PermissionComletion = (CKContainer_Application_PermissionStatus, Error?) -> Void


protocol RemoteProvider {
    func setupSubscription(fetchCompletion: @escaping () -> Void)
    func fetchChanges(in scope: CKDatabase.Scope,
                      needByPass: Bool,
                      completion: @escaping () -> Void)
    func upload(_ notes: [Note],
                savePolicy: CKModifyRecordsOperation.RecordSavePolicy,
                completion: ModifyCompletion)
    func remove(_ notes: [Note], completion: ModifyCompletion)

    func fetchUserID(completion: @escaping () -> Void)
    func createZone(completion: @escaping (Bool) -> Void)
}


final class CloudService: RemoteProvider {
    private enum SubscriptionID {
        static let privateChange = "privateChange"
        static let sharedChange = "sharedChange"
    }

    enum Record {
        static let note = "Note"
    }

    enum Field {
        // CUSTOM FIELD
        static let content = "content"
        static let isRemoved = "isRemoved"
        static let location = "location"
        static let recordID = "recordID"
        static let isLocked = "isLocked"
        static let isPinned = "isPinned"
        static let tags = "tags"
        static let createdAtLocally = "createdAtLocally"
        static let modifiedAtLocally = "modifiedAtLocally"

        // SYSTEM FIELD
        static let createdBy = "createdBy"
        static let modifiedBy = "modifiedBy"
    }

    let backgroundContext: NSManagedObjectContext

    lazy var privateQueue: OperationQueue = {
        let queue = OperationQueue()
        return queue
    }()

    init(context: NSManagedObjectContext) {
        self.backgroundContext = context
    }

    private let container = CKContainer.default()
    private var privateDatabase: CKDatabase {
        return container.privateCloudDatabase
    }
    private var sharedDatabase: CKDatabase {
        return container.sharedCloudDatabase
    }

    func setupSubscription(fetchCompletion: @escaping () -> Void) {
        addDatabaseSubscription(completion: fetchCompletion)
    }

    func fetchChanges(
        in scope: CKDatabase.Scope,
        needByPass: Bool = false,
        completion: @escaping () -> Void) {

        func enqueue(database: CKDatabase) {
            let fetchDatabaseChange = FetchDatabaseChangeOperation(database: database)
            let fetchZoneChange = FetchZoneChangeOperation(database: database)
            let handlerZoneChange = HandleZoneChangeOperation(
                recordHandler: self,
                needByPass: needByPass
            )
            let completionOperation = BlockOperation(block: completion)
            fetchZoneChange.addDependency(fetchDatabaseChange)
            handlerZoneChange.addDependency(fetchZoneChange)
            completionOperation.addDependency(handlerZoneChange)

            self.privateQueue.addOperations(
                [fetchDatabaseChange, fetchZoneChange, handlerZoneChange, completionOperation],
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

    func upload(
        _ notes: [Note],
        savePolicy: CKModifyRecordsOperation.RecordSavePolicy = .ifServerRecordUnchanged,
        completion: ModifyCompletion) {

        let recordToSaveForPrivate = notes.filter { $0.isMine }.map { $0.cloudKitRecord }
        let recordToSaveForShared = notes.filter { !$0.isMine }.map { $0.cloudKitRecord }

        if recordToSaveForPrivate.count > 0 {
            modifyRequest(database: privateDatabase, recordToSave: recordToSaveForPrivate, savePolicy: savePolicy, completion: completion)
        }
        if recordToSaveForShared.count > 0 {
            modifyRequest(database: sharedDatabase, recordToSave: recordToSaveForPrivate, savePolicy: savePolicy, completion: completion)
        }
    }

    func remove(_ notes: [Note], completion: ModifyCompletion) {
        let recordIDsToDeleteForPrivate = notes.filter { $0.isMine }.compactMap { $0.remoteID }
        let recordIDsToDeleteForShared = notes.filter { !$0.isMine }.compactMap { $0.remoteID }

        if recordIDsToDeleteForPrivate.count > 0 {
            modifyRequest(database: privateDatabase, recordIDsToDelete: recordIDsToDeleteForPrivate, completion: completion)
        }
        if recordIDsToDeleteForShared.count > 0 {
            modifyRequest(database: sharedDatabase, recordIDsToDelete: recordIDsToDeleteForShared, completion: completion)
        }
    }

    func fetchUserID(completion: @escaping () -> Void) {
        let requestUserID = RequestUserIDOperation(container: container)
        let block = BlockOperation(block: completion)
        block.addDependency(requestUserID)
        privateQueue.addOperations([requestUserID, block], waitUntilFinished: false)
    }

    func createZone(completion: @escaping (Bool) -> Void) {
        let zoneID = CKRecordZone.ID(zoneName: "Notes", ownerName: CKCurrentUserDefaultName)
        let notesZone = CKRecordZone(zoneID: zoneID)
        let operation = CKModifyRecordZonesOperation()
        operation.recordZonesToSave = [notesZone]
        operation.modifyRecordZonesCompletionBlock = {
            _, _, operationError in
            if operationError == nil {
                UserDefaults.standard.set(true, forKey: "createdCustomZone")
                completion(true)
                return
            } else if let ckError = operationError as? CKError,
                ckError.isSpecificErrorCode(code: .partialFailure) {
                UserDefaults.standard.set(true, forKey: "createdCustomZone")
                completion(true)
                return
            }
            completion(false)
        }
        privateDatabase.add(operation)
    }

    private func modifyRequest(
        database: CKDatabase,
        recordToSave: [CKRecord]? = nil,
        recordIDsToDelete: [CKRecord.ID]? = nil,
        savePolicy: CKModifyRecordsOperation.RecordSavePolicy = .ifServerRecordUnchanged,
        completion: ModifyCompletion = nil) {

        let op = CKModifyRecordsOperation(
            recordsToSave: recordToSave,
            recordIDsToDelete: recordIDsToDelete
        )
        op.savePolicy = savePolicy
        op.qualityOfService = .userInitiated
        op.modifyRecordsCompletionBlock = { completion?($0, $1, $2) }
        database.add(op)
    }

}

extension CloudService {
    private func addDatabaseSubscription(completion: @escaping () -> Void) {
        func fetchBoth() {
            self.fetchChanges(in: .private, completion: completion)
            self.fetchChanges(in: .shared) { }
        }
        if !UserDefaults.standard.bool(forKey: "createdCustomZone") {
            let createZone = CreateZoneOperation(database: privateDatabase)
            let block = BlockOperation {
                fetchBoth()
            }
            block.addDependency(createZone)
            privateQueue.addOperations([createZone, block], waitUntilFinished: false)
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

        //        if subscriptionID == SubscriptionID.sharedChange {
        //            info.alertBody = "Shared Changed"
        //        } else {
        //            info.alertBody = "Private Changed"
        //        }
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info
        let operation = CKModifySubscriptionsOperation(
            subscriptionsToSave: [subscription],
            subscriptionIDsToDelete: nil
        )
        return operation
    }
}

