//
// Created by 김범수 on 2018. 4. 19..
// Copyright (c) 2018 piano. All rights reserved.
//
/*
import CloudKit

extension RxCloudDatabase {
    //for public & private. Shared DB doesn't accept this subscription
    func saveQuerySubscription(for recordType: String) {
        let subscriptionKey = "ckQuerySubscriptionSaved\(recordType)\(database.databaseScope.string)"
        let alreadySaved = UserDefaults.standard.bool(forKey: subscriptionKey)
        guard !alreadySaved else {return}

        let predicate = NSPredicate(value: true)

        let subscription = CKQuerySubscription(recordType: recordType, predicate: predicate,
                subscriptionID: subscriptionKey, options: [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate])

        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo

        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: nil)
        operation.modifySubscriptionsCompletionBlock = { (_, _, error) in
            guard error == nil else {return}
            UserDefaults.standard.set(true, forKey: subscriptionKey)
        }
        operation.qualityOfService = .utility

        database.add(operation)
    }


    func saveDatabaseSubscription() {
        let subscriptionKey = "ckDatabaseSubscription\(database.databaseScope.string)"
        let alreadySaved = UserDefaults.standard.bool(forKey: subscriptionKey)
        guard !alreadySaved else {return}

        let subscription = CKDatabaseSubscription(subscriptionID: subscriptionKey)

        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo

        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: nil)
        operation.modifySubscriptionsCompletionBlock = { (_, _, error) in
            guard error == nil else {return}
            UserDefaults.standard.set(true, forKey: subscriptionKey)
        }
        operation.qualityOfService = .utility

        database.add(operation)
    }
}

extension RxCloudDatabase {
    ///public database
    func query(for recordType: String, recordFetchedBlock: ((CKRecord) -> Void)? = nil,
               completion: ((CKQueryCursor?, Error?) -> Void)? = nil) {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        let isShared = self.database.databaseScope == .shared

        let operation = CKQueryOperation(query: query)
        
        operation.recordFetchedBlock = recordFetchedBlock ?? {[weak self] (record) in
            self?.syncChanged(record: record, isShared: isShared)
        }
        
        operation.queryCompletionBlock = completion
        
        operation.qualityOfService = .utility

        database.add(operation)
    }

    ///private db, shared db
    func fetchZoneChanges(in recordZoneIDs: [CKRecordZoneID]) {
        let userID = CloudManager.shared.userID?.recordName ?? ""
        var optionDic: [CKRecordZoneID: CKFetchRecordZoneChangesOptions] = [:]
        let isShared = self.database.databaseScope == .shared

        for zoneID in recordZoneIDs {
            let options = CKFetchRecordZoneChangesOptions()
            let serverChangedTokenKey = "ckServerZoneChangeToken\(userID)\(zoneID)\(database.databaseScope.string)"

            if let changeTokenData = UserDefaults.standard.data(forKey: serverChangedTokenKey) {
                options.previousServerChangeToken = CKServerChangeToken.unarchieve(from: changeTokenData) as? CKServerChangeToken
            }
            optionDic[zoneID] = options
        }

        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: recordZoneIDs, optionsByRecordZoneID: optionDic)
        operation.fetchAllChanges = false

        operation.recordChangedBlock = {[weak self] record in
            self?.syncChanged(record: record, isShared: isShared)
        }

        operation.recordWithIDWasDeletedBlock = {[weak self] recordID, recordType in
            self?.syncDeleted(recordID: recordID, recordType: recordType)
        }

        operation.recordZoneChangeTokensUpdatedBlock = {[weak self] zoneID, changeToken, _ in
            guard let changedToken = changeToken,
                    let database = self?.database else {return}
            let serverChangedTokenKey = "ckServerZoneChangeToken\(userID)\(zoneID)\(database.databaseScope.string)"
            UserDefaults.standard.set(changedToken.archieve(), forKey: serverChangedTokenKey)
        }

        operation.recordZoneFetchCompletionBlock = { [weak self] zoneID, changeToken, data, more, error in
            guard error == nil, let changedToken = changeToken,
                    let database = self?.database else {return}
            let serverChangedTokenKey = "ckServerZoneChangeToken\(userID)\(zoneID)\(database.databaseScope.string)"

            UserDefaults.standard.set(changedToken.archieve(), forKey: serverChangedTokenKey)

            if more { self?.fetchZoneChanges(in: [zoneID]) }
        }
        
        operation.qualityOfService = .utility
        database.add(operation)
    }

    func fetchDatabaseChanges() {
        let userID = CloudManager.shared.userID?.recordName ?? ""
        let serverChangedTokenKey = "ckDatabaseChangeToken\(userID)\(database.databaseScope.string)"
        var changeToken: CKServerChangeToken?

        if let changeTokenData = UserDefaults.standard.data(forKey: serverChangedTokenKey) {
            changeToken = CKServerChangeToken.unarchieve(from: changeTokenData) as? CKServerChangeToken
        }

        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: changeToken)
        operation.fetchAllChanges = false

        operation.changeTokenUpdatedBlock = { changedToken in
            UserDefaults.standard.set(changedToken.archieve(), forKey: serverChangedTokenKey)
        }

        operation.fetchDatabaseChangesCompletionBlock = { [weak self] changeToken, more, error in
            guard error == nil, let changedToken = changeToken else {return}
            UserDefaults.standard.set(changedToken.archieve(), forKey: serverChangedTokenKey)

            if more { self?.fetchDatabaseChanges() }
        }

        let fetchHandler: ((CKRecordZoneID) -> Void) = {[weak self] recordID in
            self?.fetchZoneChanges(in: [recordID])
        }

        operation.recordZoneWithIDChangedBlock = fetchHandler
        operation.recordZoneWithIDWasDeletedBlock = fetchHandler
        if #available(iOS 11.0, *) { operation.recordZoneWithIDWasPurgedBlock = fetchHandler }

        operation.qualityOfService = .utility

        database.add(operation)
    }
}
 
 */
