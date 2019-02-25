//
//  FetchDatabaseChangeOperation.swift
//  Piano
//
//  Created by hoemoon on 23/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit

/// 변경된 zone 식별자 목록을 표현합니다.
/// FetchZoneChangeOperation에서 이 프로토콜을 준수하는 인스턴스에서 식별자 목록을 사용합니다.
protocol CloudDatabaseChangeProvider {
    var changedZoneIDs: [CKRecordZone.ID] { get }
    var error: Error? { get }
}

/// 인스턴스를 생성할 때, 인자로 받는 database에 대한 변경사항을 요청합니다.
/// needRefreshToken이 true일 경우 로컬에 저장된 server changed token을 무시합니다.
class FetchDatabaseChangeOperation: AsyncOperation, CloudDatabaseChangeProvider {
    private let database: CKDatabase
    var changedZoneIDs: [CKRecordZone.ID] = []
    var error: Error?
    var needRefreshToken = false

    init(database: CKDatabase, needRefreshToken: Bool = false) {
        self.database = database
        self.needRefreshToken = needRefreshToken
        super.init()
    }

    override func main() {
        let key = "databaseChange\(database.databaseScope.rawValue)"
        var token = UserDefaults.getServerChangedToken(key: key)
        if needRefreshToken {
            token = nil
        }
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
            if error != nil {
                self.error = error
                self.state = .Finished
                return
            }
            UserDefaults.setServerChangedToken(key: key, token: token)
            self.state = .Finished
        }
        database.add(operation)
    }
}
