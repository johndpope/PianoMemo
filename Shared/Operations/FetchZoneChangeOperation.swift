//
//  FetchZoneChangeOperation.swift
//  Piano
//
//  Created by hoemoon on 23/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit

protocol ZoneChangeProvider {
    var newRecords: [RecordWrapper] { get }
    var removedReocrdIDs: [CKRecord.ID] { get }
}

class FetchZoneChangeOperation: AsyncOperation, ZoneChangeProvider {
    typealias Options = CKFetchRecordZoneChangesOperation.ZoneOptions
    private let database: CKDatabase

    var newRecords = [RecordWrapper]()
    var removedReocrdIDs = [CKRecord.ID]()

    private var databaseChangeProvider: CloudDatabaseChangeProvider? {
        if let provider = dependencies
            .filter({$0 is CloudDatabaseChangeProvider})
            .first as? CloudDatabaseChangeProvider {
            return provider
        }
        return nil
    }

    init(database: CKDatabase) {
        self.database = database
        super.init()
    }

    override func main() {
        guard let changeProvider = databaseChangeProvider else {
            self.state = .Finished
            return
        }
        let zoneIDs = changeProvider.changedZoneIDs
        var optionsByRecordZoneID = [CKRecordZone.ID: Options]()
        for zoneID in zoneIDs {
            let options = Options()
            let key = "zoneChange\(database.databaseScope)\(zoneID)"
            let token = UserDefaults.getServerChangedToken(key: key)
            options.previousServerChangeToken = token
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
                // 쉐어 accept시에 여기로 1
                let isMine = self.database.databaseScope == .private
                self.newRecords.append((isMine, record))
            }
        }
        operation.recordWithIDWasDeletedBlock = {
            [weak self] recordID, _ in
            guard let self = self else { return }
            self.removedReocrdIDs.append(recordID)
        }
        operation.recordZoneChangeTokensUpdatedBlock = {
            zoneID, token, _ in
            let key = "fetchOperation\(self.database.databaseScope)\(zoneID)"
            UserDefaults.setServerChangedToken(key: key, token: token)
            print("recordZoneChangeTokensUpdatedBlock😎", self.database.databaseScope, zoneID)
        }
        operation.recordZoneFetchCompletionBlock = {
            zoneID, token, _, _, error in
            let key = "zoneChange\(self.database.databaseScope)\(zoneID)"
            UserDefaults.setServerChangedToken(key: key, token: token)
            print("recordZoneFetchCompletionBlock😎", self.database.databaseScope.rawValue, zoneID)
        }
        operation.fetchRecordZoneChangesCompletionBlock = {
            [weak self] error in
            guard let self = self else { return }
            self.state = .Finished
            print("fetchRecordZoneChangesCompletionBlock😎", self.database.databaseScope.rawValue)
        }
        database.add(operation)
    }
}
