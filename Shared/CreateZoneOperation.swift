//
//  CreateZoneOperation.swift
//  Piano
//
//  Created by hoemoon on 10/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit

class CreateZoneOperation: AsyncOperation {
    private let database: CKDatabase

    init(database: CKDatabase) {
        self.database = database
    }
    override func main() {
        let zoneID = CKRecordZone.ID(zoneName: "Notes", ownerName: CKCurrentUserDefaultName)
        let notesZone = CKRecordZone(zoneID: zoneID)
        let operation = CKModifyRecordZonesOperation()
        operation.recordZonesToSave = [notesZone]
        operation.modifyRecordZonesCompletionBlock = {
            [weak self] _, _, operationError in


            self?.state = .Finished
        }
        database.add(operation)
    }
}
