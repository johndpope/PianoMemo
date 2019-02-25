//
//  FetchZoneChangeOperation.swift
//  Piano
//
//  Created by hoemoon on 23/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit

/// zone의 변경 사항을 표현하는 protocol
/// 이 프로토콜이 제공하는 정보는 HandleZoneChangeOperation에서 사용됩니다.
protocol ZoneChangeProvider {
    var newRecords: [RecordWrapper] { get }
    var removedReocrdIDs: [CKRecord.ID] { get }
    var error: Error? { get }
}

/// CloudDatabaseChangeProvider에서 제공받은 정보를 이용해
/// zone에 대한 변경사항을 요청합니다.
class FetchZoneChangeOperation: AsyncOperation, ZoneChangeProvider {
    typealias Options = CKFetchRecordZoneChangesOperation.ZoneOptions
    private let database: CKDatabase
    private let needRefreshToken: Bool

    var newRecords = [RecordWrapper]()
    var removedReocrdIDs = [CKRecord.ID]()
    var error: Error?

    private var databaseChangeProvider: CloudDatabaseChangeProvider? {
        if let provider = dependencies
            .filter({$0 is CloudDatabaseChangeProvider})
            .first as? CloudDatabaseChangeProvider {
            return provider
        }
        return nil
    }

    init(database: CKDatabase, needRefreshToken: Bool = false) {
        self.database = database
        self.needRefreshToken = needRefreshToken
        super.init()
    }

    override func main() {
        guard let changeProvider = databaseChangeProvider else {
            self.state = .Finished
            return
        }
        if let error = changeProvider.error {
            self.error = error
            self.state = .Finished
            return
        }
        let zoneIDs = changeProvider.changedZoneIDs
        var optionsByRecordZoneID = [CKRecordZone.ID: Options]()
        for zoneID in zoneIDs {
            let options = Options()
            let key = "zoneChange\(database.databaseScope.rawValue)\(zoneID.zoneName)"
            var token = UserDefaults.getServerChangedToken(key: key)
            if needRefreshToken {
                token = nil
            }
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
                if record.recordType == "Folder" {
                    self.newRecords.insert((isMine, record), at: 0)
                } else {
                    self.newRecords.append((isMine, record))
                }
            }
        }
        operation.recordWithIDWasDeletedBlock = {
            [weak self] recordID, _ in
            guard let self = self else { return }
            self.removedReocrdIDs.append(recordID)
        }
        operation.recordZoneChangeTokensUpdatedBlock = {
            zoneID, token, _ in
            if let token = token {
                let key = "fetchOperation\(self.database.databaseScope.rawValue)\(zoneID.zoneName)"
                UserDefaults.setServerChangedToken(key: key, token: token)
            }
        }
        operation.recordZoneFetchCompletionBlock = {
            zoneID, token, _, _, error in
            if let token = token {
                let key = "zoneChange\(self.database.databaseScope.rawValue)\(zoneID.zoneName)"
                UserDefaults.setServerChangedToken(key: key, token: token)
            }
        }
        operation.fetchRecordZoneChangesCompletionBlock = {
            [weak self] error in
            guard let self = self else { return }
            if error != nil {
                self.error = error
            }
            self.state = .Finished
        }
        database.add(operation)
    }
}
