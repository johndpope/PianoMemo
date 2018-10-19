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

protocol RemoteStorageServiceDelegate: class {
    var container: CKContainer { get }
    var privateDatabase: CKDatabase { get }
    var sharedDatabase: CKDatabase { get }

    func fetchChanges(in scope: CKDatabase.Scope, completion: @escaping () -> Void)
    func acceptShare(metadata: CKShare.Metadata, completion: @escaping () -> Void)
    func requestUserRecordID(completion: @escaping (CKAccountStatus, CKUserIdentity?, Error?) -> Void)
    func setup()
    func requestUserIdentity(userRecordID: CKRecord.ID, completion: @escaping (CKUserIdentity?, Error?) -> Void)
    func requestShare(
        recordToShare: CKRecord,
        preparationHandler: @escaping PreparationHandler)
    func requestFetchRecords(
        by recordIDs: [CKRecord.ID],
        isMine: Bool,
        completion: @escaping ([CKRecord.ID : CKRecord]?, Error?) -> Void)
    func requestAddFetchedRecords(
        by recordIDs: [CKRecord.ID],
        isMine: Bool,
        completion: @escaping () -> Void)

    func requestApplicationPermission(completion: @escaping (CKContainer_Application_PermissionStatus, Error?) -> Void)
}

class RemoteStorageSerevice: RemoteStorageServiceDelegate {
    weak var localStorageServiceDelegate: LocalStorageServiceDelegate!
    lazy var container = CKContainer.default()
    lazy var privateDatabase = container.privateCloudDatabase
    lazy var sharedDatabase = container.sharedCloudDatabase
//    private lazy var publicDatabase = container.publicCloudDatabase

    private lazy var createZoneGroup = DispatchGroup()

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
        addSubscription()
        let requestUserID = RequestUserIDOperation(container: container)
        localStorageServiceDelegate.serialQueue.addOperation(requestUserID)
    }

    private func addSubscription() {
        addDatabaseSubscription {

        }
    }

    private func addDatabaseSubscription(completion: @escaping () -> Void) {
        func fetchBothChanges(completion: @escaping () -> Void) {
            self.fetchChanges(in: .private) { completion() }
            self.fetchChanges(in: .shared) { completion() }
        }

        if !UserDefaults.standard.bool(forKey: "createdCustomZone") {
            createZoneGroup.enter()
            createZone { [weak self] error in
                if error == nil {
                    UserDefaults.standard.set(true, forKey: "createdCustomZone")
                }
                self?.createZoneGroup.leave()
            }
        } else {
            fetchBothChanges(completion: completion)
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

        createZoneGroup.notify(queue: DispatchQueue.global()) {
            if UserDefaults.standard.bool(forKey: "createdCustomZone") {
                fetchBothChanges(completion: completion)
            }
        }
    }

    func fetchChanges(in scope: CKDatabase.Scope, completion: @escaping () -> Void) {
        switch scope {
        case .private:
            fetchDatabaseChange(database: privateDatabase, completion: completion)
        case .shared:
            fetchDatabaseChange(database: sharedDatabase, completion: completion)
        case .public:
            fatalError()
        }
    }

    private func fetchDatabaseChange(
        database: CKDatabase,
        completion: @escaping () -> Void) {

        var changedZoneIDs: [CKRecordZone.ID] = []
        let key = "databaseChange\(database.databaseScope)"
        let token = UserDefaults.getServerChangedToken(key: key)
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: token)

        operation.recordZoneWithIDChangedBlock = { zoneID in
            changedZoneIDs.append(zoneID)
        }
        operation.changeTokenUpdatedBlock = { token in
            UserDefaults.setServerChangedToken(key: key, token: token)
        }
        operation.fetchDatabaseChangesCompletionBlock = {
            [weak self] token, _, error in
            if let error = error {
                // TODO: handler error
                print(error)
                completion()
                return
            }
            UserDefaults.setServerChangedToken(key: key, token: token)
            self?.fetchZoneChanges(database: database, zoneIDs: changedZoneIDs) {
//                completion()
            }
        }
        database.add(operation)
    }

    private func fetchZoneChanges(
        database: CKDatabase,
        zoneIDs: [CKRecordZone.ID],
        completion: @escaping () -> Void) {

        typealias Options = CKFetchRecordZoneChangesOperation.ZoneOptions
        var optionsByRecordZoneID = [CKRecordZone.ID: Options]()
        for zoneID in zoneIDs {
            let options = Options()
            let key = "zoneChange\(database.databaseScope)\(zoneID)"
            options.previousServerChangeToken = UserDefaults.getServerChangedToken(key: key)
            optionsByRecordZoneID[zoneID] = options
        }

        let operation = CKFetchRecordZoneChangesOperation(
            recordZoneIDs: zoneIDs,
            optionsByRecordZoneID: optionsByRecordZoneID
        )
        operation.recordChangedBlock = { [weak self] record in
            if record is CKShare {
                // TODO: 공유 후에 참여자 정보가 CKShare 형태로 넘어온다.
                // 당장은 쓸 곳이 없으니까 pass
                // 취소해도 불

                // 쉐어 accept시에 여기로 2
            } else {
                if database == self?.privateDatabase {
                    self?.localStorageServiceDelegate.add(record, isMine: true)
                } else {
                    // 쉐어 accept시에 여기로 1
                    self?.localStorageServiceDelegate.add(record, isMine: false)

                }
            }
        }
        operation.recordWithIDWasDeletedBlock = {
            [weak self] recordID, _ in
            self?.localStorageServiceDelegate.purge(recordID: recordID)
        }
        // The new change token from the server.
        // You can store this token locally and use it during subsequent fetch operations
        // to limit the results to records that changed since this operation executed.
        operation.recordZoneChangeTokensUpdatedBlock = {
            zoneID, token, _ in
            let key = "fetchOperation\(database.databaseScope)\(zoneID)"
            UserDefaults.setServerChangedToken(key: key, token: token)
//            print(token, "recordZoneChangeTokensUpdatedBlock")
        }
        operation.recordZoneFetchCompletionBlock = {
            zoneID, token, _, _, error in
            let key = "zoneChange\(database.databaseScope)\(zoneID)"
            UserDefaults.setServerChangedToken(key: key, token: token)
        }
        operation.fetchRecordZoneChangesCompletionBlock = {
            error in
            completion()
        }
        database.add(operation)
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

    private func createZone(completion: @escaping (Error?) -> Void) {
        let zoneID = CKRecordZone.ID(zoneName: "Notes", ownerName: CKCurrentUserDefaultName)
        let notesZone = CKRecordZone(zoneID: zoneID)
        let operation = CKModifyRecordZonesOperation()
        operation.recordZonesToSave = [notesZone]
        operation.modifyRecordZonesCompletionBlock = {
            _, _, operationError in
            completion(operationError)
        }
        privateDatabase.add(operation)
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

    func acceptShare(metadata: CKShare.Metadata, completion: @escaping () -> Void) {
        let operation = CKAcceptSharesOperation(shareMetadatas: [metadata])
        operation.perShareCompletionBlock = {
            metadata, share, error in
            // 1
        }
        operation.acceptSharesCompletionBlock = { error in
            // 2
            if error != nil {
                OperationQueue.main.addOperation {
                    completion()
                }
            }
        }
        container.add(operation)
    }

    func requestUserRecordID(completion: @escaping (CKAccountStatus, CKUserIdentity?, Error?) -> Void) {
        guard UserDefaults.getUserIdentity() == nil else { return }
        container.accountStatus { [weak self] status, error in
            if status == .available {
                self?.container.fetchUserRecordID { recordID, error in
                    if let recordID = recordID {
                        self?.container.discoverUserIdentity(withUserRecordID: recordID) {
                            identity, error in
                            if let identity = identity {
                                completion(.available, identity, nil)
                            }
                        }
                    } else {
                        completion(.available, nil, error)
                    }
                }
            } else {
                completion(status, nil, nil)
            }
        }
    }

    func requestUserIdentity(userRecordID: CKRecord.ID, completion: @escaping (CKUserIdentity?, Error?) -> Void) {
        container.discoverUserIdentity(withUserRecordID: userRecordID) { identity, error in
            completion(identity, error)
        }
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

        let operation = CKFetchRecordsOperation(recordIDs: recordIDs)
        operation.fetchRecordsCompletionBlock = {
            [weak self] recordsByRecordID, operationError in
            guard let self = self else { return }

            if let recordsByRecordID = recordsByRecordID {
                let add = AddFetcedRecordsOperation(
                    context: self.localStorageServiceDelegate.backgroundContext,
                    queue: self.localStorageServiceDelegate.serialQueue
                )
                add.isMine = isMine
                add.recordIDs = recordIDs
                add.recordsByRecordID = recordsByRecordID
                add.completion = completion
                self.localStorageServiceDelegate.serialQueue.addOperation(add)
            }
        }
        if isMine {
            privateDatabase.add(operation)
        } else {
            sharedDatabase.add(operation)
        }
    }

    func requestApplicationPermission(completion: @escaping (CKContainer_Application_PermissionStatus, Error?) -> Void) {
        container.requestApplicationPermission(.userDiscoverability) {
            applicationPermissionStatus, error in
            completion(applicationPermissionStatus, error)
        }
    }
}
