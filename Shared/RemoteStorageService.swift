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
    func upload(notes: Array<Note>, completionHandler: @escaping ([CKRecord], Error?) -> Void)
}

class RemoteStorageSerevice: RemoteStorageServiceType {
    static let notesZoneID = CKRecordZone.ID(zoneName: "Notes", ownerName: CKCurrentUserDefaultName)

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

    func upload(notes: Array<Note>, completionHandler: @escaping ([CKRecord], Error?) -> Void) {
        let operation = CKModifyRecordsOperation()
        operation.recordsToSave = notes.map { $0.recodify() }
        operation.modifyRecordsCompletionBlock = {
            [weak self] savedRecords, _, operationError in

            if let ckError = operationError as? CKError {
                if ckError.isSpecificErrorCode(code: .zoneNotFound) {
                    self?.createZone { [weak self] error in
                        if error == nil {
                            self?.upload(notes: notes, completionHandler: completionHandler)
                        } else {
                            completionHandler([], nil)
                        }
                    }
                } else if ckError.isSpecificErrorCode(code: .serverRecordChanged) {
                    fatalError()
                }
            } else if let savedRecords = savedRecords {
                completionHandler(savedRecords, nil)
            }
        }
        privateDatabase.add(operation)
    }

    private func createZone(completionHandler: @escaping (Error?) -> Void) {
        let notesZone = CKRecordZone(zoneID: RemoteStorageSerevice.notesZoneID)
        let operation = CKModifyRecordZonesOperation()
        operation.recordZonesToSave = [notesZone]
        operation.modifyRecordZonesCompletionBlock = {
            _, _, operationError in
            completionHandler(operationError)
        }
        privateDatabase.add(operation)
    }
}

private extension Note {
    typealias Fields = RemoteStorageSerevice.NoteFields
    func recodify() -> CKRecord {
        var record: CKRecord!

        switch self.recordArchive {
        case .some(let archive):
            if let recorded = archive.ckRecorded {
                record = recorded
            }
        case .none:
            let id = CKRecord.ID(recordName: UUID().uuidString, zoneID: RemoteStorageSerevice.notesZoneID)
            record = CKRecord(recordType: RemoteStorageSerevice.Records.note, recordID: id)

            // save recordID to persistent storage
            recordID = record.recordID
        }

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

private extension Data {
    var ckRecorded: CKRecord? {
        let unarchiver = NSKeyedUnarchiver(forReadingWith: self)
        unarchiver.requiresSecureCoding = true
        let record = CKRecord(coder: unarchiver)
        unarchiver.finishDecoding()
        return record
    }
}
