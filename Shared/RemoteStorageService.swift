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
//    func upload(_ records: Array<CKRecord>, completionHandler: @escaping ([CKRecord], Error?) -> Void)
    func fetchChanges(in scope: CKDatabase.Scope, completion: @escaping () -> Void)
    func requestShare(
        record: CKRecord,
        title: String?,
        thumbnailImageData: Data?,
        preparationHandler: @escaping PreparationHandler)
    func acceptShare(metadata: CKShare.Metadata, completion: @escaping () -> Void)
    func requestUserRecordID(completion: @escaping (CKAccountStatus, CKUserIdentity?, Error?) -> Void)
    func setup()
    func requestModify(
        recordsToSave: Array<CKRecord>?,
        recordsToDelete: Array<CKRecord>?,
        completion: @escaping ([CKRecord]?, [CKRecord.ID]?, Error?) -> Void)
}

class RemoteStorageSerevice: RemoteStorageServiceDelegate {
    weak var localStorageServiceDelegate: LocalStorageServiceDelegate!
    private lazy var container = CKContainer.default()
    private lazy var privateDatabase = container.privateCloudDatabase
    private lazy var sharedDatabase = container.sharedCloudDatabase
//    private lazy var publicDatabase = container.publicCloudDatabase

    private var createdCustomZone = false
    private var subscribedToPrivateChanges = false
    private var subscribedToSharedChanged = false

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
        static let isTrash = "isTrash"
        static let location = "location"
        static let recordID = "recordID"

        // SYSTEM FIELD
        static let createdAt = "createdAt"
        static let createdBy = "createdBy"
        static let modifiedAt = "modifiedAt"
        static let modifiedBy = "modifiedBy"
    }

    func setup() {
        addSubscription()
        requestUserRecordID { status, identity, error in
            if error == nil, let identity = identity {
                UserDefaults.setUserIdentity(identity: identity)
            }
        }
    }

    func requestModify(
        recordsToSave: Array<CKRecord>?,
        recordsToDelete: Array<CKRecord>?,
        completion: @escaping ([CKRecord]?, [CKRecord.ID]?, Error?) -> Void) {

        if let recordsToSave = recordsToSave {
            let shared = recordsToSave.filter { $0.isShared }
            let privateRecords = recordsToSave.filter { !$0.isShared }
            if shared.count > 0 {
                requestModify(shared, nil, sharedDatabase, completion: completion)
            }
            if privateRecords.count > 0 {
                requestModify(privateRecords, nil, privateDatabase, completion: completion)
            }
        } else if let recordsToDelete = recordsToDelete {
            let shared = recordsToDelete.filter { $0.isShared }
            let privateRecords = recordsToDelete.filter { !$0.isShared }
            if shared.count > 0 {
                requestModify(nil, shared.map { $0.recordID }, sharedDatabase, completion: completion)
            }
            if privateRecords.count > 0 {
                requestModify(nil, privateRecords.map { $0.recordID }, privateDatabase, completion: completion)
            }
        }
    }

    private func requestModify(
        _ recordsToSave: Array<CKRecord>?,
        _ recordIDsToDelete: Array<CKRecord.ID>?,
        _ database: CKDatabase,
        completion: @escaping ([CKRecord]?, [CKRecord.ID]?, Error?) -> Void) {

        let operation = CKModifyRecordsOperation()
        operation.savePolicy = .ifServerRecordUnchanged
        operation.recordsToSave = recordsToSave
        operation.recordIDsToDelete = recordIDsToDelete
        operation.qualityOfService = .userInitiated
        operation.modifyRecordsCompletionBlock = {
            [weak self] saves, deletedIDs, error in

            if let ckError = error as? CKError {
                if ckError.isSpecificErrorCode(code: .zoneNotFound) {
                    self?.createZone { [weak self] error in
                        if error == nil {
                            self?.requestModify(
                                recordsToSave,
                                recordIDsToDelete,
                                database,
                                completion: completion
                            )
                        } else {
                            completion(nil, nil, error)
                        }
                    }
                } else if ckError.isSpecificErrorCode(code: .serverRecordChanged) {
                    if let record = self?.resolve(error: ckError) {
                        self?.requestModify(
                            [record],
                            nil,
                            database,
                            completion: completion
                        )
                    }
                } else {
                    print(ckError)
                    fatalError()
                }
            } else if let saves = saves {
                completion(saves, nil, nil)
            } else if let deletedIDs = deletedIDs {
                completion(nil, deletedIDs, nil)
            }
        }
        database.add(operation)
    }

    private func addSubscription() {
        addDatabaseSubscription { [weak self] in
            self?.localStorageServiceDelegate.refreshUI {}
        }
    }

    private func addDatabaseSubscription(completion: @escaping () -> Void) {
        if !createdCustomZone {
            createZoneGroup.enter()
            createZone { [weak self] error in
                if error == nil {
                    self?.createdCustomZone = true
                }
                self?.createZoneGroup.leave()
            }
        }

        if !subscribedToPrivateChanges {
            let databaseSubscriptionOperation = createDatabaseSubscriptionOperation(with: SubscriptionID.privateChange)
            databaseSubscriptionOperation.modifySubscriptionsCompletionBlock = {
                [weak self] subscriptions, iDs, error in
                if error == nil {
                    self?.subscribedToPrivateChanges = true
                }
            }
            privateDatabase.add(databaseSubscriptionOperation)
        }
        if !subscribedToSharedChanged {
            let databaseSubscriptionOperation = createDatabaseSubscriptionOperation(with: SubscriptionID.sharedChange)
            databaseSubscriptionOperation.modifySubscriptionsCompletionBlock = {
                [weak self] subscriptions, iDs, error in
                if error == nil {
                    self?.subscribedToSharedChanged = true
                }
            }
            sharedDatabase.add(databaseSubscriptionOperation)
        }

        createZoneGroup.notify(queue: DispatchQueue.global()) { [weak self] in
            guard let `self` = self else { return }
            if self.createdCustomZone {
                self.fetchChanges(in: .private) { completion() }
                self.fetchChanges(in: .shared) { completion() }
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
            self?.fetchZoneChanges(database: database, zoneIDs: changedZoneIDs) {
                UserDefaults.setServerChangedToken(key: key, token: token)
                completion()
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
            let options = CKFetchRecordZoneChangesOperation.ZoneOptions()
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
            } else {
                self?.localStorageServiceDelegate.addNote(record)
            }
        }
        operation.recordWithIDWasDeletedBlock = {
            [weak self] recordID, _ in
            self?.localStorageServiceDelegate.purge(recordID: recordID)
        }
        operation.recordZoneChangeTokensUpdatedBlock = {
            zoneID, token, _ in
            let key = "zoneChange\(database.databaseScope)\(zoneID)"
            UserDefaults.setServerChangedToken(key: key, token: token)
        }
        operation.recordZoneFetchCompletionBlock = {
            zoneID, token, data, moreComing, error in
            let key = "zoneChange\(database.databaseScope)\(zoneID)"
            UserDefaults.setServerChangedToken(key: key, token: token)
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
        guard let clientRecord = records.1,
            let serverRecord = records.2 else { return nil }

        if let serverModifiedAt = serverRecord[NoteFields.modifiedAt] as? Date,
            let clientMotifiedAt = clientRecord[NoteFields.modifiedAt] as? Date,
            let clientContent = clientRecord[NoteFields.content] as? String,
            let serverContent = serverRecord[NoteFields.content] as? String {

            if serverModifiedAt > clientMotifiedAt {
                serverRecord[NoteFields.content] = ConflictResolver()
                    .positiveMerge(old: clientContent, new: serverContent) as CKRecordValue
            } else {
                serverRecord[NoteFields.content] = ConflictResolver()
                    .positiveMerge(old: serverContent, new: clientContent) as CKRecordValue
            }
        }
        return serverRecord
    }

    func requestShare(
        record: CKRecord,
        title: String?,
        thumbnailImageData: Data?,
        preparationHandler: @escaping PreparationHandler) {

        let ckShare = CKShare(rootRecord: record)
        ckShare[CKShare.SystemFieldKey.title] = title
        ckShare[CKShare.SystemFieldKey.thumbnailImageData] = thumbnailImageData
        let operation = CKModifyRecordsOperation()
        operation.recordsToSave = [record, ckShare]
        operation.modifyRecordsCompletionBlock = {
            [weak self] _, _, operationError in
            
            preparationHandler(ckShare, self?.container, operationError)
        }
        privateDatabase.add(operation)
    }

    func acceptShare(metadata: CKShare.Metadata, completion: @escaping () -> Void) {
        let operation = CKAcceptSharesOperation(shareMetadatas: [metadata])
        operation.perShareCompletionBlock = {
            metadata, share, error in

        }
        operation.acceptSharesCompletionBlock = { error in

            completion()
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
}

extension Note {
    typealias Fields = RemoteStorageSerevice.NoteFields
    func recodify() -> CKRecord {
        var record: CKRecord!

        switch recordArchive {
        case .some(let archive):
            if let recorded = archive.ckRecorded {
                record = recorded
            }
        case .none:
            let zoneID = CKRecordZone.ID(zoneName: "Notes", ownerName: CKCurrentUserDefaultName)
            let id = CKRecord.ID(
                recordName: UUID().uuidString,
                zoneID: zoneID
            )
            record = CKRecord(recordType: RemoteStorageSerevice.Records.note, recordID: id)
            // save recordID to persistent storage
            recordID = record.recordID

        }

        if let content = content {
            record[Fields.content] = content as CKRecordValue
        }
        if let location = location as? CLLocation {
            record[Fields.location] = location
        }
        record[Fields.isTrash] = (isTrash ? 1 : 0) as CKRecordValue

        return record
    }
}

private extension CKRecord {
    var isShared: Bool {
        return share != nil
    }
}

extension Data {
    var ckRecorded: CKRecord? {
        let coder = NSKeyedUnarchiver(forReadingWith: self)
        coder.requiresSecureCoding = true
        let record = CKRecord(coder: coder)
        coder.finishDecoding()
        return record
    }
}

extension UserDefaults {
    static func getServerChangedToken(key: String) -> CKServerChangeToken? {
        if let data = standard.data(forKey: key),
            let token = NSKeyedUnarchiver.unarchiveObject(with: data) as? CKServerChangeToken {
            return token
        }
        return nil
    }

    static func setServerChangedToken(key: String, token: CKServerChangeToken?) {
        guard let token = token else { return }
        let data = NSKeyedArchiver.archivedData(withRootObject: token)
        standard.set(data, forKey: key)
    }

    static func getUserIdentity() -> CKUserIdentity? {
        let key = "userIdentity"
        if let data = standard.data(forKey: key),
            let record = NSKeyedUnarchiver.unarchiveObject(with: data) as? CKUserIdentity {
            return record
        }
        return nil
    }
    static func setUserIdentity(identity: CKUserIdentity) {
        let data = NSKeyedArchiver.archivedData(withRootObject: identity)
        standard.set(data, forKey: "userIdentity")
    }
}
