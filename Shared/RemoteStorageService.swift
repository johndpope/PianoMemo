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

protocol RemoteStorageServiceDelegate: class {
    func upload(notes: Array<Note>, completionHandler: @escaping ([CKRecord], Error?) -> Void)

    func fetchChanges(in scope: CKDatabase.Scope, completion: @escaping () -> Void)
}

class RemoteStorageSerevice: RemoteStorageServiceDelegate {
    static let notesZoneID = CKRecordZone.ID(zoneName: "Notes", ownerName: CKCurrentUserDefaultName)

    weak var localStorageServiceDelegate: LocalStorageServiceDelegate!

    private lazy var container = CKContainer.default()

    private lazy var privateDatabase = container.privateCloudDatabase
    private lazy var sharedDatabase = container.sharedCloudDatabase
    private lazy var publicDatabase = container.publicCloudDatabase

    private var createdCustomZone = false
    private var subscribedToPrivateChanges = false
    private var subscribedToSharedChanged = false

    private let createZoneGroup = DispatchGroup()

    enum SubscriptionID {
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
    }

    func upload(notes: Array<Note>, completionHandler: @escaping ([CKRecord], Error?) -> Void) {
        let operation = CKModifyRecordsOperation()
        operation.recordsToSave = notes.map { $0.recodify() }
        operation.modifyRecordsCompletionBlock = {
            [weak self] savedRecords, _, operationError in

            if let ckError = operationError as? CKError {
                if ckError.isSpecificErrorCode(code: .zoneNotFound) {
                    self?.createZone { [weak self] error in
                        if error == nil {
                            self?.upload(notes: notes, completionHandler: completionHandler)
                        } else {
                            completionHandler([], nil)
                        }
                    }
                } else if ckError.isSpecificErrorCode(code: .serverRecordChanged) {
                    // TODO:
                    fatalError()
                }
            } else if let savedRecords = savedRecords {
                completionHandler(savedRecords, nil)
            }
        }
        privateDatabase.add(operation)
    }

    private func addSubscription() {
//        addZoneSubscription()
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
            self?.localStorageServiceDelegate.addNote(record)
        }
        operation.recordWithIDWasDeletedBlock = {
            recordID, recordType in
            // TODO: delete
        }
        operation.recordZoneChangeTokensUpdatedBlock = {
            recordZoneID, token, _ in
            let key = "zoneChange\(database.databaseScope)\(recordZoneID)"
            UserDefaults.setServerChangedToken(key: key, token: token)
        }
        operation.recordZoneFetchCompletionBlock = {
            recordZoneID, token, clientChangeTokenData, moreComing, error in
            let key = "zoneChange\(database.databaseScope)\(recordZoneID)"
            UserDefaults.setServerChangedToken(key: key, token: token)
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
        let notesZone = CKRecordZone(zoneID: RemoteStorageSerevice.notesZoneID)
        let operation = CKModifyRecordZonesOperation()
        operation.recordZonesToSave = [notesZone]
        operation.modifyRecordZonesCompletionBlock = {
            _, _, operationError in
            completion(operationError)
        }
        privateDatabase.add(operation)
    }
}

private extension Note {
    typealias Fields = RemoteStorageSerevice.NoteFields
    func recodify() -> CKRecord {
        var record: CKRecord!

        switch self.recordArchive {
        case .some(let archive):
            if let recorded = archive.ckRecorded {
                record = recorded
            }
        case .none:
            let id = CKRecord.ID(
                recordName: UUID().uuidString,
                zoneID: RemoteStorageSerevice.notesZoneID
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

private extension Data {
    var ckRecorded: CKRecord? {
        let coder = NSKeyedUnarchiver(forReadingWith: self)
        coder.requiresSecureCoding = true
        let record = CKRecord(coder: coder)
        coder.finishDecoding()
        return record
    }
}

private extension UserDefaults {
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
        UserDefaults.standard.set(data, forKey: key)
    }
}
