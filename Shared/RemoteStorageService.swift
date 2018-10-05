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
    func upload(_ records: Array<CKRecord>, completionHandler: @escaping ([CKRecord], Error?) -> Void)
    func fetchChanges(in scope: CKDatabase.Scope, completion: @escaping () -> Void)
    func requestShare(
        record: CKRecord,
        title: String?,
        thumbnailImageData: Data?,
        preparationHandler: @escaping PreparationHandler)
    func acceptShare(metadata: CKShare.Metadata, completion: @escaping () -> Void)
    func requestUserRecordID(completion: @escaping () -> Void)
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
        static let attributeData = "attributeData"
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

    init() {
        addSubscription()
        requestUserRecordID { }
    }

    func upload(_ records: Array<CKRecord>, completionHandler: @escaping ([CKRecord], Error?) -> Void) {
        upload(records.filter { $0.isMyRecord }, database: sharedDatabase, completionHandler: completionHandler)
        upload(records.filter { !$0.isMyRecord }, database: privateDatabase, completionHandler: completionHandler)
    }

    private func upload(
        _ records: Array<CKRecord>,
        database: CKDatabase,
        completionHandler: @escaping ([CKRecord], Error?) -> Void) {

        guard records.count > 0 else { return }
        let operation = CKModifyRecordsOperation()
        operation.savePolicy = .ifServerRecordUnchanged
        operation.recordsToSave = records
        operation.modifyRecordsCompletionBlock = {
            [weak self] savedRecords, _, operationError in

            if let ckError = operationError as? CKError {
                if ckError.isSpecificErrorCode(code: .zoneNotFound) {
                    self?.createZone { [weak self] error in
                        if error == nil {
                            self?.upload(records, completionHandler: completionHandler)
                        } else {
                            completionHandler([], nil)
                        }
                    }
                } else if ckError.isSpecificErrorCode(code: .serverRecordChanged) {
                    if let record = self?.resolve(error: ckError) {
                        self?.upload([record], completionHandler: completionHandler)
                    }
                }
            } else if let savedRecords = savedRecords {
                completionHandler(savedRecords, nil)
            }
        }
        database.add(operation)
    }

    private func addSubscription() {
        addDatabaseSubscription()
    }

    private func addDatabaseSubscription() {
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
                self.fetchChanges(in: .private) {}
                self.fetchChanges(in: .shared) {}
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
            recordID, recordType in
            // TODO: delete
        }
        operation.recordZoneChangeTokensUpdatedBlock = {
            zoneID, token, _ in
            let key = "zoneChange\(database.databaseScope)\(zoneID)"
            UserDefaults.setServerChangedToken(key: key, token: token)
        }
        operation.recordZoneFetchCompletionBlock = {
            [weak self] zoneID, token, data, moreComing, error in
            let key = "zoneChange\(database.databaseScope)\(zoneID)"
            UserDefaults.setServerChangedToken(key: key, token: token)
            self?.localStorageServiceDelegate.refreshContext()
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

        // TODO: enhance resolve logic
        serverRecord[NoteFields.content] = clientRecord[NoteFields.content]
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

    func requestUserRecordID(completion: @escaping () -> Void) {
//        guard UserDefaults.getUserRecordID() == nil else { return }
        container.accountStatus { [weak self] status, error in
            if status == .available {
                self?.container.fetchUserRecordID { recordID, error in
                    if error == nil {
                        self?.container.discoverUserIdentity(withUserRecordID: recordID!) {
                            identity, error in
                            if error == nil {
                                UserDefaults.setUserRecordID(recordID: identity!.userRecordID)
                                completion()
                            }
                        }
                    }
                }
            }
        }
    }
}

extension Note {
    typealias Fields = RemoteStorageSerevice.NoteFields
    func recodify() -> CKRecord {
        var record: CKRecord!

        switch self.recordArchive {
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

        if let attributeData = attributeData {
            record[Fields.attributeData] = attributeData as CKRecordValue
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
    var isMyRecord: Bool {
      return recordID.zoneID.ownerName != CKCurrentUserDefaultName
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

    static func getUserRecordID() -> CKRecord.ID? {
        let key = "userRecordID"
        if let data = standard.data(forKey: key),
            let record = NSKeyedUnarchiver.unarchiveObject(with: data) as? CKRecord.ID {
            return record
        }
        return nil
    }
    static func setUserRecordID(recordID: CKRecord.ID?) {
        guard let recordID = recordID else { return }
        let data = NSKeyedArchiver.archivedData(withRootObject: recordID)
        standard.set(data, forKey: "userRecordID")
    }
}