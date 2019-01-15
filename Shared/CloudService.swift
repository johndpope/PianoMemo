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
typealias NoteField = CloudService.NoteField
typealias ImageField = CloudService.ImageField
typealias PreparationHandler = ((CKShare?, CKContainer?, Error?) -> Void)
typealias PermissionComletion = (CKContainer_Application_PermissionStatus, Error?) -> Void

protocol RemoteProvider {
    func setup(context: NSManagedObjectContext)
    func fetchChanges(
        in scope: CKDatabase.Scope,
        needByPass: Bool,
        needRefreshToken: Bool,
        completion: @escaping (Bool) -> Void
    )
    func upload(
        _ notes: [CloudKitRecordable],
        savePolicy: CKModifyRecordsOperation.RecordSavePolicy,
        completion: ModifyCompletion
    )
    func remove(
        _ notes: [CloudKitRecordable],
        savePolicy: CKModifyRecordsOperation.RecordSavePolicy,
        completion: ModifyCompletion
    )
    func fetchUserID(completion: @escaping () -> Void)
    func createZone(completion: @escaping (Bool) -> Void)
}

final class CloudService: RemoteProvider {
    var retriedErrorCodes = [Int]()
    private enum SubscriptionID {
        static let privateChange = "privateChange"
        static let sharedChange = "sharedChange"
    }

    enum Record {
        static let note = "Note"
        static let image = "Image"
    }

    enum NoteField {
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
        static let folder = "folder"

        // SYSTEM FIELD
        static let createdBy = "createdBy"
        static let modifiedBy = "modifiedBy"
    }

    enum ImageField {
        static let imageData = "imageData"

        static let createdAtLocally = "createdAtLocally"
        static let modifiedAtLocally = "modifiedAtLocally"

//        static let createdBy = "createdBy"
//        static let modifiedBy = "modifiedBy"
    }

    var backgroundContext: NSManagedObjectContext!

    lazy var privateQueue: OperationQueue = {
        let queue = OperationQueue()
        return queue
    }()

    private let container = CKContainer.default()
    private var privateDatabase: CKDatabase {
        return container.privateCloudDatabase
    }
    private var sharedDatabase: CKDatabase {
        return container.sharedCloudDatabase
    }

    func setup(context: NSManagedObjectContext) {
        self.backgroundContext = context
        addDatabaseSubscription()
    }

    func fetchChanges(
        in scope: CKDatabase.Scope,
        needByPass: Bool = false,
        needRefreshToken: Bool = false,
        completion: @escaping (Bool) -> Void) {

        func enqueue(database: CKDatabase) {
            let fetchDatabaseChange = FetchDatabaseChangeOperation(
                database: database,
                needRefreshToken: needRefreshToken
            )
            let fetchZoneChange = FetchZoneChangeOperation(
                database: database,
                needRefreshToken: needRefreshToken
            )
            let handlerZoneChange = HandleZoneChangeOperation(
                scope: scope,
                recordHandler: self,
                errorHandler: self,
                needByPass: needByPass,
                completion: completion
            )
            fetchZoneChange.addDependency(fetchDatabaseChange)
            handlerZoneChange.addDependency(fetchZoneChange)

            self.privateQueue.addOperations(
                [fetchDatabaseChange, fetchZoneChange, handlerZoneChange],
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
        _ recordable: [CloudKitRecordable],
        savePolicy: CKModifyRecordsOperation.RecordSavePolicy = .ifServerRecordUnchanged,
        completion: ModifyCompletion) {

        let recordToSaveForPrivate = recordable.filter { $0.isMine }.compactMap { $0.cloudKitRecord }
        let recordToSaveForShared = recordable.filter { !$0.isMine }.compactMap { $0.cloudKitRecord }

        if recordToSaveForPrivate.count > 0 {
            modifyRequest(
                database: privateDatabase,
                recordToSave: recordToSaveForPrivate,
                savePolicy: savePolicy,
                completion: completion
            )
        }
        if recordToSaveForShared.count > 0 {
            modifyRequest(
                database: sharedDatabase,
                recordToSave: recordToSaveForPrivate,
                savePolicy: savePolicy,
                completion: completion
            )
        }
    }

    func remove(
        _ recordable: [CloudKitRecordable],
        savePolicy: CKModifyRecordsOperation.RecordSavePolicy = .ifServerRecordUnchanged,
        completion: ModifyCompletion) {

        let recordIDsToDeleteForPrivate = recordable.filter { $0.isMine }
            .compactMap { $0.cloudKitRecord }
            .map { $0.recordID }
        let recordIDsToDeleteForShared = recordable.filter { !$0.isMine }
            .compactMap { $0.cloudKitRecord }
            .map { $0.recordID }

        if recordIDsToDeleteForPrivate.count > 0 {
            modifyRequest(
                database: privateDatabase,
                recordIDsToDelete: recordIDsToDeleteForPrivate,
                savePolicy: savePolicy,
                completion: completion
            )
        }
        if recordIDsToDeleteForShared.count > 0 {
            modifyRequest(
                database: sharedDatabase,
                recordIDsToDelete: recordIDsToDeleteForShared,
                savePolicy: savePolicy,
                completion: completion
            )
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
    private func addDatabaseSubscription() {
        if !UserDefaults.standard.bool(forKey: "createdCustomZone") {
            let createZone = CreateZoneOperation(database: privateDatabase)
            privateQueue.addOperations([createZone], waitUntilFinished: false)
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

protocol FetchErrorHandlable: class {
    var retriedErrorCodes: [Int] { get set }
    func handleError(error: Error?, completion: @escaping () -> Void)
}

extension CloudService: FetchErrorHandlable {
    func handleError(error: Error?, completion: @escaping () -> Void) {
        func flush() { retriedErrorCodes.removeAll() }

        guard let ckError = error as? CKError, !retriedErrorCodes.contains(ckError.errorCode) else { return }
        retriedErrorCodes.append(ckError.errorCode)

        switch ckError.code {
        case .changeTokenExpired:
            retryRequest(needRefreshToken: true) {
                if $0 { flush() }
                completion()
            }
        case .serviceUnavailable, .requestRateLimited, .zoneBusy:
            if let number = ckError.userInfo[CKErrorRetryAfterKey] as? NSNumber {
                DispatchQueue.global().asyncAfter(deadline: .now() + Double(truncating: number)) { [weak self] in
                    guard let self = self else { return }
                    self.retryRequest(completion: { success in
                        if success { flush() }
                        completion()
                    })
                }
            }
        case .networkFailure, .networkUnavailable, .serverResponseLost:
            retryRequest { success in
                if success { flush() }
                completion()
            }
        default:
            completion()
        }
    }

    private func retryRequest(
        error: CKError? = nil,
        needRefreshToken: Bool = false,
        completion: @escaping (Bool) -> Void) {

        fetchChanges(in: .private, needRefreshToken: needRefreshToken) { [weak self] in
            guard let self = self, $0 == true else { completion(false); return }
            self.fetchChanges(in: .shared, needRefreshToken: needRefreshToken) { success in
                if success { completion(true) }
            }
        }
    }
}
