//
//  RemoteProvider.swift
//  Piano
//
//  Created by hoemoon on 15/02/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import CoreData
import CloudKit

/// 원격 서버와의 통신에 대한 인터페이스를 정의하는 프로토콜 입니다.
protocol RemoteProvider {
    func setup(context: NSManagedObjectContext)
    func fetchChanges(
        in scope: CKDatabase.Scope,
        needByPass: Bool,
        needRefreshToken: Bool,
        completion: @escaping (Bool) -> Void
    )
    func upload(
        _ notes: [CloudKitRecordable],
        savePolicy: CKModifyRecordsOperation.RecordSavePolicy,
        completion: ModifyCompletion
    )
    func remove(
        _ notes: [CloudKitRecordable],
        savePolicy: CKModifyRecordsOperation.RecordSavePolicy,
        completion: ModifyCompletion
    )
    func fetchUserID(completion: @escaping (String?) -> Void)
    func createZone(completion: @escaping (Bool) -> Void)
    func addDatabaseSubscription()
}
