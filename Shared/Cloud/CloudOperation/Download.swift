//
//  Fetch.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 4..
//

import CloudKit

#if os(iOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

/// CKFetchRecordZoneChangesOperation.
public class Download: ErrorHandleable {
    
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
    
    #if os(iOS)
    /**
     UserInfo에 담겨있는 정보 또는 cloud 변경점을 바탕으로 download를 진행한다.
     - Parameter info: UserInfo notification.
     - Note: default값으로 진행시 cloud의 변경점에 대한 전체 download를 진행한다.
     */
    public func operate(with info: [AnyHashable : Any]? = nil, _ completion: ((UIBackgroundFetchResult) -> ())? = nil) {
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
        result(with: info, completion)
    }
    
    /**
     UserInfo에 담겨있는 cloud 정보를 바탕으로 UIBackgroundFetchResult를 처리한다.
     - Parameter info: UserInfo notification.
     - Parameter completionHandler: UIBackgroundFetchResult.
     */
    private func result(with info: [AnyHashable : Any]?, _ completion: ((UIBackgroundFetchResult) -> ())?) {
        if let dic = info as? [String: NSObject] {
            let noti = CKNotification(fromRemoteNotificationDictionary: dic)
            if let id = noti.subscriptionID {
                if [PRIVATE_DB_ID, SHARED_DB_ID, PUBLIC_DB_ID].contains(id) {
                    completion?(.newData)
                } else {
                    completion?(.noData)
                }
            } else {
                completion?(.failed)
            }
        } else {
            completion?(.failed)
        }
    }
    #elseif os(OSX)
    // TODO:...
    public func operate() {}
    #endif
    
}

internal extension Download {
    
    internal func zoneOperation(zoneID: CKRecordZone.ID = ZONE_ID, token key: String = PRIVATE_DB_ID, _ database: CKDatabase) {
        
        var optionDic = [CKRecordZone.ID: CKFetchRecordZoneChangesOperation.ZoneOptions]()
        let option = CKFetchRecordZoneChangesOperation.ZoneOptions()
        option.previousServerChangeToken = token.byZoneID[key]
        optionDic[zoneID] = option
        
        let context = container.coreData.newBackgroundContext()
        context.name = FETCH_CONTEXT
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneID], optionsByRecordZoneID: optionDic)
        operation.recordChangedBlock = { record in
            self.modify.operate(record, context)
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
        }
        database.add(operation)
    }
    
    internal func dbOperation(_ database: CKDatabase) {
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: token.byZoneID[DATABASE_DB_ID])
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

