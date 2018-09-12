//
//  Zone.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 4..
//

internal class Zone {
    
    private let container: Container
    
    internal init(with container: Container) {
        self.container = container
    }
    
    internal func operate(_ completion: @escaping (() -> ())) {
        let recordZone = CKRecordZone(zoneName: ZONE_ID.zoneName)
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [recordZone], recordZoneIDsToDelete: nil)
        operation.completionBlock = {completion()}
        container.cloud.privateCloudDatabase.add(operation)
    }
    
}
