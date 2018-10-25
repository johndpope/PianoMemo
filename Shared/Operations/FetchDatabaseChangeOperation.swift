//
//  FetchDatabaseChangeOperation.swift
//  Piano
//
//  Created by hoemoon on 23/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit

protocol CloudDatabaseChangeProvider {
    var changedZoneIDs: [CKRecordZone.ID] { get }
}

class FetchDatabaseChangeOperation: AsyncOperation, CloudDatabaseChangeProvider {
    private let database: CKDatabase
    var changedZoneIDs: [CKRecordZone.ID] = []

    init(database: CKDatabase) {
        self.database = database
        super.init()
    }

    override func main() {
        let key = "databaseChange\(database.databaseScope)"
        let token = UserDefaults.getServerChangedToken(key: key)
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: token)

        operation.recordZoneWithIDChangedBlock = {
            [weak self] zoneID in
            self?.changedZoneIDs.append(zoneID)
        }
        operation.changeTokenUpdatedBlock = { token in
            UserDefaults.setServerChangedToken(key: key, token: token)
        }
        operation.fetchDatabaseChangesCompletionBlock = {
            [weak self] token, _, error in
            guard let self = self else { return }
            if let error = error {
                // TODO: handler error
                print(error)
                self.state = .Finished
                return
            }
            UserDefaults.setServerChangedToken(key: key, token: token)
            self.state = .Finished
        }
        database.add(operation)
    }
}
