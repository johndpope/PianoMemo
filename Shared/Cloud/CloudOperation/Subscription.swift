//
//  Subscription.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 4..
//

import CloudKit

/// CKModifySubscriptionsOperation.
internal class Subscription: ErrorHandleable {
    
    internal var container: Container
    internal var errorBlock: ((Error?) -> ())?
    
    private let dispatchGroup = DispatchGroup()
    
    internal init(with container: Container) {
        self.container = container
    }
    
    internal func operate(_ completion: @escaping (() -> ())) {
        errorBlock = {self.errorHandle(subscription: $0)}
        dispatchGroup.enter()
        DispatchQueue.global().async(group: dispatchGroup) {
            self.zoneOperation {self.dispatchGroup.leave()}
        }
        dispatchGroup.enter()
        DispatchQueue.global().async(group: dispatchGroup) {
            self.databaseOperation {self.dispatchGroup.leave()}
        }
        dispatchGroup.notify(queue: DispatchQueue.global()) {
            completion()
        }
    }
    
}

internal extension Subscription {
    
    private func zoneOperation(_ completion: @escaping (() -> ())) {
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        let subscription = CKRecordZoneSubscription(zoneID: ZONE_ID, subscriptionID: PRIVATE_DB_ID)
        subscription.notificationInfo = notificationInfo
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
        operation.modifySubscriptionsCompletionBlock = {
            if let error = $2 as? CKError, let partialError = error.partialErrorsByItemID?.values {
                partialError.forEach {self.errorBlock?($0)}
            }
            completion()
        }
        container.cloud.privateCloudDatabase.add(operation)
    }
    
    private func databaseOperation(_ completion: @escaping (() -> ())) {
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        let subscription = CKDatabaseSubscription(subscriptionID: SHARED_DB_ID)
        subscription.notificationInfo = notificationInfo
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
        operation.modifySubscriptionsCompletionBlock = {
            if let error = $2 as? CKError, let partialError = error.partialErrorsByItemID?.values {
                partialError.forEach {self.errorBlock?($0)}
            }
            completion()
        }
        container.cloud.sharedCloudDatabase.add(operation)
    }
    
}

