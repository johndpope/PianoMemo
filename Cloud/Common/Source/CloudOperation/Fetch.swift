//
//  Fetch.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 4..
//

/// CKFetchRecordZoneChangesOperation.
public class Fetch: ErrorHandleable {
    
    internal var container: Container
    internal var errorBlock: ((Error?) -> ())?
    
    private var delete: Delete!
    private var modify: Modify!
    internal let token = CloudToken.loadFromUserDefaults()
    
    internal init(with container: Container) {
        self.container = container
        delete = Delete(with: container)
        modify = Modify(with: container)
    }
    
    /**
     UserInfo에 담겨있는 cloud 정보를 바탕으로 fetch를 진행한다.
     - Parameter info: UserInfo notification.
     - Note: info를 default로 진행시엔 모든 database에 대한 fetch를 진행한다.
     */
    public func operate(with info: [AnyHashable : Any]? = nil) {
        if let dic = info as? [String: NSObject] {
            let noti = CKNotification(fromRemoteNotificationDictionary: dic)
            guard let id = noti.subscriptionID else {return}
            if id == PRIVATE_DB_ID {
                zoneOperation(container.cloud.privateCloudDatabase)
            } else {
                dbOperation(container.cloud.sharedCloudDatabase)
            }
        } else {
            zoneOperation(container.cloud.privateCloudDatabase)
            dbOperation(container.cloud.sharedCloudDatabase)
        }
    }
    
}

internal extension Fetch {
    
    internal func zoneOperation(zoneID: CKRecordZoneID = ZONE_ID, token key: String = PRIVATE_DB_ID, _ database: CKDatabase) {
        
        var optionDic = [CKRecordZoneID: CKFetchRecordZoneChangesOptions]()
        let option = CKFetchRecordZoneChangesOptions()
        option.previousServerChangeToken = token.byZoneID[key]
        optionDic[zoneID] = option
        
        let context = container.coreData.viewContext
        context.name = FETCH_CONTEXT
        var changedRecords = [CKRecord]()
        
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneID], optionsByRecordZoneID: optionDic)
        operation.qualityOfService = .utility
        operation.recordChangedBlock = { record in
            self.modify.operate(record, context)
            changedRecords.append(record)
        }
        operation.recordWithIDWasDeletedBlock = { recordID, _ in
            self.delete.operate(recordID, context)
        }
        operation.recordZoneChangeTokensUpdatedBlock = { _, token, _ in
            self.token.byZoneID[key] = token
        }
        operation.recordZoneFetchCompletionBlock = { _, token, _, _, error in
            self.token.byZoneID[key] = token
            if let error = error {self.errorHandle(fetch: error, database)}
            if changedRecords.isEmpty {
                if context.hasChanges {try? context.save()}
            } else {
                self.modify.operate(forReference: changedRecords, context)
            }
            context.name = nil
        }
        database.add(operation)
    }
    
    internal func dbOperation(_ database: CKDatabase) {
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: token.byZoneID[DATABASE_DB_ID])
        operation.qualityOfService = .utility
        operation.changeTokenUpdatedBlock = {self.token.byZoneID[DATABASE_DB_ID] = $0}
        operation.fetchDatabaseChangesCompletionBlock = { token, isMore, error in
            self.token.byZoneID[DATABASE_DB_ID] = token
            if isMore {self.dbOperation(database)}
            if let error = error {self.errorHandle(fetch: error, database)}
        }
        operation.recordZoneWithIDChangedBlock = {self.zoneOperation(zoneID: $0, token: SHARED_DB_ID, database)}
        operation.recordZoneWithIDWasDeletedBlock = {self.zoneOperation(zoneID: $0, token: SHARED_DB_ID, database)}
        operation.recordZoneWithIDWasPurgedBlock = {self.zoneOperation(zoneID: $0, token: SHARED_DB_ID, database)}
        database.add(operation)
    }
    
}
