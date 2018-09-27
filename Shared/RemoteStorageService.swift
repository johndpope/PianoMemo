//
//  RemoteStorageService.swift
//  Piano
//
//  Created by hoemoon on 26/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit

/// 원격 저장소에 접근하는 모든 인터페이스 제공

protocol RemoteStorageServiceType: class {
    func upload(notes: Set<Note>, completionHandler: @escaping ([CKRecord]) -> Void)
}

class RemoteStorageSerevice: RemoteStorageServiceType {
    static let zoneID = CKRecordZone.ID(zoneName: "Notes", ownerName: CKCurrentUserDefaultName)

    private lazy var container = CKContainer.default()

    lazy var privateDatabase = container.privateCloudDatabase
    lazy var sharedDatabase = container.sharedCloudDatabase
    lazy var publicDatabase = container.publicCloudDatabase

    enum Records {
        static let note = "Note"
    }

    enum NoteFields {
        // CUSTOM FIELD
        static let attributeData = "attributeData"
        static let content = "content"
        static let isTrash = "isTrash"
        static let location = "location"
        static let recordID = "recordID"

        // SYSTEM FIELD
        static let createdAt = "createdAt"
        static let createdBy = "createdBy"
        static let modifiedAt = "modifiedAt"
        static let modifiedBy = "modifiedBy"
    }

    func upload(notes: Set<Note>, completionHandler: @escaping ([CKRecord]) -> Void) {
        let operation = CKModifyRecordsOperation()
        operation.recordsToSave = notes.map { $0.newRecord() }
        operation.modifyRecordsCompletionBlock = {
            savedRecords, _, operationError in

            if operationError != nil {
                // TODO: 에러 처리
                fatalError()
            } else if let savedRecords = savedRecords {
                completionHandler(savedRecords)
            }
        }
        privateDatabase.add(operation)
    }
}

private extension Note {
    typealias Fields = RemoteStorageSerevice.NoteFields
    func newRecord() -> CKRecord {
        let record = CKRecord(recordType: RemoteStorageSerevice.Records.note)
        recordID = record.recordID
        if let attributeData = attributeData {
            record[Fields.attributeData] = attributeData as CKRecordValue
        }
        if let content = content {
            record[Fields.content] = content as CKRecordValue
        }
        if let location = location as? CLLocation {
            record[Fields.location] = location
        }
        record[Fields.isTrash] = (isTrash ? 1 : 0) as CKRecordValue
        return record
    }
}
