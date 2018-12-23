//
//  CloudKitService.swift
//  Piano
//
//  Created by hoemoon on 22/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CloudKit

typealias ModifyCompletion = (([CKRecord]?, [CKRecord.ID]?, Error?) -> Void)?

protocol RemoteProvider {
    func setupSubscription()
    func fetchLatests(completion: @escaping ([RemoteNote]) -> Void)
    func fetchNews(completion: @escaping ([RemoteRecordChange<RemoteNote>], @escaping (_ success: Bool) -> Void) -> Void)

    func upload(_ notes: [Note], completion: ModifyCompletion)
    func remove(_ notes: [Note], completion: ModifyCompletion)

    func fetchUserID(completion: @escaping (CKRecord.ID?) -> Void)
}


final class CloudService: RemoteProvider {

    let container = CKContainer.default()

    var privateDB: CKDatabase {
        return container.privateCloudDatabase
    }

    var sharedDB: CKDatabase {
        return container.sharedCloudDatabase
    }

    func setupSubscription() {
    }

    func fetchLatests(completion: @escaping ([RemoteNote]) -> Void) {
    }

    func fetchNews(completion: @escaping ([RemoteRecordChange<RemoteNote>], @escaping (Bool) -> Void) -> Void) {
    }

    func upload(_ notes: [Note], completion: ModifyCompletion) {
        let recordToSave = notes.map { $0.cloudKitRecord }
        modifyRequest(recordToSave: recordToSave, completion: completion)
    }

    func remove(_ notes: [Note], completion: ModifyCompletion) {
        let recordIDsToDelete = notes.compactMap { $0.remoteID }
        modifyRequest(recordIDsToDelete: recordIDsToDelete, completion: completion)
    }

    func fetchUserID(completion: @escaping (CKRecord.ID?) -> Void) {
    }

    private func modifyRequest(
        recordToSave: [CKRecord]? = nil,
        recordIDsToDelete: [CKRecord.ID]? = nil,
        completion: ModifyCompletion) {

        let op = CKModifyRecordsOperation(
            recordsToSave: recordToSave,
            recordIDsToDelete: recordIDsToDelete
        )
        op.savePolicy = .ifServerRecordUnchanged
        op.qualityOfService = .userInitiated
        op.modifyRecordsCompletionBlock = { completion?($0, $1, $2) }
        privateDB.add(op)
    }
}

struct RemoteNote: RemoteRecord {

    init() {

    }
}

enum RemoteError {

}
