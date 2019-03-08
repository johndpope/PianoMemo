//
//  CKDatabase_extension.swift
//  Piano
//
//  Created by 박주혁 on 07/03/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation
import CloudKit

extension CKDatabase {
    
    public var isSubscriptionLocallyCached: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "\(self.databaseScope.rawValue)DatabaseSubscribed")
        } set {
            UserDefaults.standard.set(newValue, forKey: "\(self.databaseScope.rawValue)DatabaseSubscribed")
        }
    }
    
    public func subscribe() {
        let subscription = CKDatabaseSubscription(subscriptionID: "\(self.databaseScope.rawValue)DatabaseChanges")
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        let operation = CKModifySubscriptionsOperation(
            subscriptionsToSave: [subscription],
            subscriptionIDsToDelete: nil)
        operation.modifySubscriptionsCompletionBlock = { (subscriptions, ids, error) in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            self.isSubscriptionLocallyCached = true
        }
        operation.qualityOfService = .utility
        self.add(operation)
    }
    
    public func fetchChanges(_ completion: @escaping () -> Void) {
        var changedRecordZoneIDs = [CKRecordZone.ID]()
        let data = UserDefaults.standard.data(forKey: "\(self.databaseScope.rawValue)DatabaseChangeToken")
        let previousToken = serverChangeToken(from: data)
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: previousToken)
        operation.fetchAllChanges = true
        operation.recordZoneWithIDChangedBlock = { (recordZoneID) in
            changedRecordZoneIDs.append(recordZoneID)
        }
        operation.changeTokenUpdatedBlock = { (serverChangeToken) in
            let data = self.tokenData(from: serverChangeToken)
            UserDefaults.standard.set(data, forKey: "\(self.databaseScope.rawValue)DatabaseChangeToken")
        }
        operation.fetchDatabaseChangesCompletionBlock = { (serverChangeToken, isMore, error) in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            let data = self.tokenData(from: serverChangeToken)
            UserDefaults.standard.set(data, forKey: "\(self.databaseScope.rawValue)DatabaseChangeToken")
            self.fetchRecordZone(changedRecordZoneIDs, completion: completion)
        }
        self.add(operation)
    }
    
    private func fetchRecordZone(_ ids: [CKRecordZone.ID], completion: @escaping () -> Void) {
        typealias Options = [CKRecordZone.ID: CKFetchRecordZoneChangesOperation.ZoneOptions]
        var options: Options {
            var result = Options()
            ids.forEach{ zoneID in
                let zoneOptions = CKFetchRecordZoneChangesOperation.ZoneOptions()
                let data = UserDefaults.standard.data(forKey: "\(zoneID.zoneName)ZoneChangeToken")
                let previousToken = self.serverChangeToken(from: data)
                zoneOptions.previousServerChangeToken = previousToken
                result[zoneID] = zoneOptions
            }
            return result
        }
        
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: ids, optionsByRecordZoneID: options)
        operation.fetchAllChanges = true
        operation.recordChangedBlock = { record in
            //Coredata 에서 업데이트 하는 로직
            //노트.폴더.에셋 등 여러가지가 될 수 있다.
        }
        operation.recordWithIDWasDeletedBlock = { recordID, recordType in
            //CoreData 에서 색인 후 삭제하는 로직
        }
        operation.recordZoneChangeTokensUpdatedBlock = { (zoneID, serverChangeToken, _) in
            let data = self.tokenData(from: serverChangeToken)
            UserDefaults.standard.set(data, forKey: "\(zoneID.zoneName)ZoneChangeToken")
        }
        var additionalFetchNeededZoneIDs = [CKRecordZone.ID]()
        operation.recordZoneFetchCompletionBlock = { (zoneID, serverChangeToken, _, isMore, error) in
            let data = self.tokenData(from: serverChangeToken)
            UserDefaults.standard.set(data, forKey: "\(zoneID.zoneName)ZoneChangeToken")
            if isMore {
                additionalFetchNeededZoneIDs.append(zoneID)
            }
        }
        operation.fetchRecordZoneChangesCompletionBlock = { error in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            guard additionalFetchNeededZoneIDs.isEmpty else {
                self.fetchRecordZone(additionalFetchNeededZoneIDs, completion: completion)
                return
            }
            completion()
        }
        self.add(operation)
    }
    
    public func modifyRecordZones(save: [CKRecordZone]? = nil, delete: [CKRecordZone.ID]? = nil, completion: (() -> Void)? = nil) {
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: save, recordZoneIDsToDelete: delete)
        operation.modifyRecordZonesCompletionBlock = {savedRecordZones, deletedRecordZones, error in
            if error != nil {
                return
            }
            completion?()
        }
        self.add(operation)
    }
    
    public func modifyRecords(save: [CKRecord]? = nil, delete: [CKRecord.ID]? = nil, completion: (() -> Void)? = nil) {
        let operation = CKModifyRecordsOperation(recordsToSave: save, recordIDsToDelete: delete)
        operation.perRecordCompletionBlock = { record, error in
            
        }
        operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecords, error in
            if error != nil {
                //Todo: handle error
                return
            }
            completion?()
        }
        self.add(operation)
    }
    
    private func tokenData(from token: CKServerChangeToken?) -> Data? {
        guard let token = token else { return nil }
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        token.encode(with: coder)
        return coder.encodedData
    }
    
    private func serverChangeToken(from data: Data?) -> CKServerChangeToken? {
        guard let data = data else { return nil }
        do {
            let coder = try NSKeyedUnarchiver(forReadingFrom: data)
            return CKServerChangeToken(coder: coder)
        } catch {
            print("fail to unarchive token")
            return nil
        }
    }
}

