//
//  FetchZoneChangeOperation.swift
//  Piano
//
//  Created by hoemoon on 23/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit

class FetchZoneChangeOperation: AsyncOperation {
    typealias Options = CKFetchRecordZoneChangesOperation.ZoneOptions

    private let database: CKDatabase
    private let syncController: Synchronizable

    private var databaseChangeResultProvider: DatabaseChangeResultProvider? {
        if let provider = dependencies
            .filter({$0 is DatabaseChangeResultProvider})
            .first as? DatabaseChangeResultProvider {
            return provider
        }
        return nil

    }

    init(database: CKDatabase, syncController: Synchronizable) {
        self.database = database
        self.syncController = syncController
        super.init()
    }

    override func main() {
        guard let resultsProvider = databaseChangeResultProvider else {
            self.state = .Finished
            return
        }
        let zoneIDs = resultsProvider.changedZoneIDs
        var optionsByRecordZoneID = [CKRecordZone.ID: Options]()
        for zoneID in zoneIDs {
            let options = Options()
            let key = "zoneChange\(database.databaseScope)\(zoneID)"
            options.previousServerChangeToken = UserDefaults.getServerChangedToken(key: key)
            optionsByRecordZoneID[zoneID] = options
        }

        let operation = CKFetchRecordZoneChangesOperation(
            recordZoneIDs: zoneIDs,
            optionsByRecordZoneID: optionsByRecordZoneID
        )
        operation.recordChangedBlock = {
            [weak self] record in
            guard let self = self else { return }
            if record is CKShare {
                // TODO: 공유 후에 참여자 정보가 CKShare 형태로 넘어온다.
                // 당장은 쓸 곳이 없으니까 pass
                // 취소해도 불

                // 쉐어 accept시에 여기로 2
            } else {
                if self.database.databaseScope == .private {
                    self.syncController.add(record, isMine: true)
                } else if self.database.databaseScope == .shared {
                    // 쉐어 accept시에 여기로 1
                    self.syncController.add(record, isMine: false)
                }
            }
        }
        operation.recordWithIDWasDeletedBlock = {
            [weak self] recordID, _ in
            guard let self = self else { return }
            self.syncController.purge(recordID: recordID)
        }
        operation.recordZoneChangeTokensUpdatedBlock = {
            zoneID, token, _ in
            let key = "fetchOperation\(self.database.databaseScope)\(zoneID)"
            UserDefaults.setServerChangedToken(key: key, token: token)
        }
        operation.recordZoneFetchCompletionBlock = {
            zoneID, token, _, _, error in
            let key = "zoneChange\(self.database.databaseScope)\(zoneID)"
            UserDefaults.setServerChangedToken(key: key, token: token)
        }
        operation.fetchRecordZoneChangesCompletionBlock = {
            error in
            self.state = .Finished
        }
        database.add(operation)
    }
}
