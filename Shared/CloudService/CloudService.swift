//
//  CloudKitService.swift
//  Piano
//
//  Created by hoemoon on 22/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CloudKit
import CoreData

typealias ModifyCompletion = (([CKRecord]?, [CKRecord.ID]?, Error?) -> Void)?
typealias Record = CloudService.Record
typealias NoteField = CloudService.NoteField
typealias PreparationHandler = ((CKShare?, CKContainer?, Error?) -> Void)
typealias PermissionComletion = (CKContainer_Application_PermissionStatus, Error?) -> Void

final class CloudService: RemoteProvider {
    var retriedErrorCodes = [Int]()

    /// 클라우드킷에 데이터베이스 변화에 대한 구독을 요청할 때 사용되는 식별자를 표현합니다.
    private enum SubscriptionID {
        static let privateChange = "privateChange"
        static let sharedChange = "sharedChange"
    }

    /// 앱 내의 레코드 이름을 표현합니다.
    enum Record {
        static let note = "Note"
        static let image = "Image"
        static let folder = "Folder"
    }

    /// 노트 레코드의 키를 표현합니다.
    /// 클라우드킷 레코드는 개발자가 정의할 수 있는 필드도 있고,
    /// 시스템이 미리 정의해놓은 필드도 있습니다.
    enum NoteField {
        // CUSTOM FIELD
        static let content = "content"
        static let isRemoved = "isRemoved"
        static let location = "location"
        static let recordID = "recordID"
        static let isLocked = "isLocked"
        static let isPinned = "isPinned"
        static let tags = "tags"
        static let createdAtLocally = "createdAtLocally"
        static let modifiedAtLocally = "modifiedAtLocally"
        static let folder = "folder"

        // SYSTEM FIELD
        static let createdBy = "createdBy"
        static let modifiedBy = "modifiedBy"
    }

    var backgroundContext: NSManagedObjectContext!

    lazy var privateQueue: OperationQueue = {
        let queue = OperationQueue()
        return queue
    }()

    private let container = CKContainer.default()
    private var privateDatabase: CKDatabase {
        return container.privateCloudDatabase
    }
    private var sharedDatabase: CKDatabase {
        return container.sharedCloudDatabase
    }

    /// 외부에서 클라우드 서비스를 준비시키는 메서드 입니다.
    /// 커스텀 존을 만들지 않은 경우에 존을 생성하고,
    /// 클라우드킷에 데이터베이스 구독을 등록하지 않은 경우 등록 합니다.
    func setup(context: NSManagedObjectContext) {
        self.backgroundContext = context
        if !UserDefaults.standard.bool(forKey: "createdCustomZone") {
            createZone { _ in }
        }
        addDatabaseSubscription()
    }

    /// 클라우드킷에서 변경된 데이터를 가져오는 메서드입니다.
    /// 이 메서드는 클라우드킷에서 노티피케이션을 받을 때 실행됩니다.
    /// 데이터를 가져오면서 changeToken을 서버로 부터 받아 로컬에 저장합니다.
    /// 이 토큰을 이용해서 필요한 부분의 데이터만 가져오게 됩니다.
    ///
    /// - Parameters:
    ///   - scope: 어떤 데이터베이스의 변경사항을 가져올 것인지 설정할 수 있습니다.
    ///   - needByPass: 리모트 노티를 받은 경우, 해당 노티를 터치하면 해당 노트로 바로 갈 수 있게 합니다.
    ///   - needRefreshToken: 저장된 토큰을 무효화하면 변경분이 아닌 데이터 전체를 요청할 수 있습니다.
    ///   - completion: 모든 fetch 작업을 마친 후 호출됩니다.
    func fetchChanges(
        in scope: CKDatabase.Scope,
        needByPass: Bool = false,
        needRefreshToken: Bool = false,
        completion: @escaping (Bool) -> Void) {

        func enqueue(database: CKDatabase) {
            let fetchDatabaseChange = FetchDatabaseChangeOperation(
                database: database,
                needRefreshToken: needRefreshToken
            )
            let fetchZoneChange = FetchZoneChangeOperation(
                database: database,
                needRefreshToken: needRefreshToken
            )
            let handlerZoneChange = HandleZoneChangeOperation(
                scope: scope,
                recordHandler: self,
                errorHandler: self,
                needByPass: needByPass,
                completion: completion
            )
            fetchZoneChange.addDependency(fetchDatabaseChange)
            handlerZoneChange.addDependency(fetchZoneChange)

            self.privateQueue.addOperations(
                [fetchDatabaseChange, fetchZoneChange, handlerZoneChange],
                waitUntilFinished: false
            )
        }
        switch scope {
        case .private:
            enqueue(database: privateDatabase)
        case .shared:
            enqueue(database: sharedDatabase)
        case .public:
            fatalError()
        }
    }

    /// 레코드를 서버로 업로드하는 메서드입니다.
    ///
    /// - Parameters:
    ///   - recordable: `CloudKitRecordable`을 준수하는 배열을 받습니다.
    ///   - savePolicy: operation을 생성할 때 사용하는 저장 정책을 설정할 수 있습니다.
    ///   - completion: 작업을 마친 후 실행됩니다.
    func upload(
        _ recordable: [CloudKitRecordable],
        savePolicy: CKModifyRecordsOperation.RecordSavePolicy = .ifServerRecordUnchanged,
        completion: ModifyCompletion) {

        // `CloudKitRecordable`을 `CKRecord`로 변환합니다.
        let recordToSaveForPrivate = recordable.filter { $0.isMine }.compactMap { $0.cloudKitRecord }
        let recordToSaveForShared = recordable.filter { !$0.isMine }.compactMap { $0.cloudKitRecord }

        if recordToSaveForPrivate.count > 0 {
            modifyRequest(
                database: privateDatabase,
                recordToSave: recordToSaveForPrivate,
                savePolicy: savePolicy,
                completion: completion
            )
        }
        if recordToSaveForShared.count > 0 {
            modifyRequest(
                database: sharedDatabase,
                recordToSave: recordToSaveForPrivate,
                savePolicy: savePolicy,
                completion: completion
            )
        }
    }

    /// 서버에 레코드 삭제를 요청하는 메서드입니다.
    ///
    /// - Parameters:
    ///   - recordable: `CloudKitRecordable`을 준수하는 배열을 받습니다.
    ///   - savePolicy: operation을 생성할 때 사용하는 저장 정책을 설정할 수 있습니다.
    ///   - completion: 작업을 마친 후 실행됩니다.
    func remove(
        _ recordable: [CloudKitRecordable],
        savePolicy: CKModifyRecordsOperation.RecordSavePolicy = .ifServerRecordUnchanged,
        completion: ModifyCompletion) {

        let recordIDsToDeleteForPrivate = recordable.filter { $0.isMine }
            .compactMap { $0.cloudKitRecord }
            .map { $0.recordID }
        let recordIDsToDeleteForShared = recordable.filter { !$0.isMine }
            .compactMap { $0.cloudKitRecord }
            .map { $0.recordID }

        if recordIDsToDeleteForPrivate.count > 0 {
            modifyRequest(
                database: privateDatabase,
                recordIDsToDelete: recordIDsToDeleteForPrivate,
                savePolicy: savePolicy,
                completion: completion
            )
        }
        if recordIDsToDeleteForShared.count > 0 {
            modifyRequest(
                database: sharedDatabase,
                recordIDsToDelete: recordIDsToDeleteForShared,
                savePolicy: savePolicy,
                completion: completion
            )
        }
    }

    /// 사용자의 고유한 식별자를 클라우드킷에 요청합니다.
    ///
    /// - Parameter completion: 완료 후 실행됩니다.
    func fetchUserID(completion: @escaping (String?) -> Void) {
        let requestUserID = FetchUserIDOperation(
            container: container,
            completion: completion
        )
        privateQueue.addOperation(requestUserID)
    }

    /// private database에서 `Notes`라는 커스텀 존을 만듭니다.
    ///
    /// - Parameter completion: 완료 후 실행됩니다.
    func createZone(completion: @escaping (Bool) -> Void) {
        let zoneID = CKRecordZone.ID(zoneName: "Notes", ownerName: CKCurrentUserDefaultName)
        let notesZone = CKRecordZone(zoneID: zoneID)
        let operation = CKModifyRecordZonesOperation()
        operation.recordZonesToSave = [notesZone]
        operation.modifyRecordZonesCompletionBlock = {
            _, _, operationError in
            if operationError == nil {
                UserDefaults.standard.set(true, forKey: "createdCustomZone")
                completion(true)
                return
            } else if let ckError = operationError as? CKError,
                ckError.isSpecificErrorCode(code: .partialFailure) {
                UserDefaults.standard.set(true, forKey: "createdCustomZone")
                completion(true)
                return
            }
            completion(false)
        }
        privateDatabase.add(operation)
    }

    /// 클라우드킷 서버에 데이터베이스 변화에 대한 구독을 등록하지 않은 경우
    /// 구독을 생성해서 등록합니다.
    func addDatabaseSubscription() {
        if !UserDefaults.standard.bool(forKey: "subscribedToPrivateChanges") {
            let databaseSubscriptionOperation = createDatabaseSubscriptionOperation(with: SubscriptionID.privateChange)
            databaseSubscriptionOperation.modifySubscriptionsCompletionBlock = {
                subscriptions, iDs, error in
                if error == nil {
                    UserDefaults.standard.set(true, forKey: "subscribedToPrivateChanges")
                } else if let ckError = error as? CKError, ckError.isSpecificErrorCode(code: .partialFailure) {
                    UserDefaults.standard.set(true, forKey: "subscribedToPrivateChanges")
                }
            }
            privateDatabase.add(databaseSubscriptionOperation)
        }
        if !UserDefaults.standard.bool(forKey: "subscribedToSharedChanges") {
            let databaseSubscriptionOperation = createDatabaseSubscriptionOperation(with: SubscriptionID.sharedChange)
            databaseSubscriptionOperation.modifySubscriptionsCompletionBlock = {
                subscriptions, iDs, error in
                if error == nil {
                    UserDefaults.standard.set(true, forKey: "subscribedToSharedChanges")
                } else if let ckError = error as? CKError, ckError.isSpecificErrorCode(code: .partialFailure) {
                    UserDefaults.standard.set(true, forKey: "subscribedToSharedChanges")
                }
            }
            sharedDatabase.add(databaseSubscriptionOperation)
        }
    }
}

extension CloudService {
    /// 실제로 클라우드킷에 요청하는 메서드이며,
    /// func upload(...)
    /// func remove(...)
    /// 두 개의 메서드에서 호출됩니다.
    ///
    /// - Parameters:
    ///   - database: 요청할 데이터베이스를 설정합니다
    ///   - recordToSave: 저장할 레코드의 배열
    ///   - recordIDsToDelete: 삭제할 레코드의 배열
    ///   - savePolicy: 저장 정책
    ///   - completion: 완료 후 실행
    private func modifyRequest(
        database: CKDatabase,
        recordToSave: [CKRecord]? = nil,
        recordIDsToDelete: [CKRecord.ID]? = nil,
        savePolicy: CKModifyRecordsOperation.RecordSavePolicy = .ifServerRecordUnchanged,
        completion: ModifyCompletion = nil) {

        let op = CKModifyRecordsOperation(
            recordsToSave: recordToSave,
            recordIDsToDelete: recordIDsToDelete
        )
        op.savePolicy = savePolicy
        op.qualityOfService = .userInitiated
        op.modifyRecordsCompletionBlock = { completion?($0, $1, $2) }
        database.add(op)
    }

    /// 데이터베이스 구독 식별자를 이용해 operation을 생성하는 메서드
    /// `addDatabaseSubscription()`에서 호출됩니다.
    ///
    /// - Parameter subscriptionID: 데이터베베이스 구독 식별자
    /// - Returns: 구독 수정 operation
    private func createDatabaseSubscriptionOperation(with subscriptionID: String) -> CKModifySubscriptionsOperation {
        let subscription = CKDatabaseSubscription(subscriptionID: subscriptionID)
        let info = CKSubscription.NotificationInfo()

        //        if subscriptionID == SubscriptionID.sharedChange {
        //            info.alertBody = "Shared Changed"
        //        } else {
        //            info.alertBody = "Private Changed"
        //        }
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info
        let operation = CKModifySubscriptionsOperation(
            subscriptionsToSave: [subscription],
            subscriptionIDsToDelete: nil
        )
        return operation
    }
}
