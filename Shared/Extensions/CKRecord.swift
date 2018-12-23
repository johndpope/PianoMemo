//
//  CKRecord.swift
//  Piano
//
//  Created by hoemoon on 10/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit

typealias RecordWrapper = (Bool, CKRecord)

extension CKRecord {
    var archived: NSData {
        let data = NSMutableData()
        let coder = NSKeyedArchiver(forWritingWith: data)
        coder.requiresSecureCoding = true
        self.encodeSystemFields(with: coder)
        coder.finishEncoding()
        return data
    }

    // TODO:
    var isShared: Bool {
        return share != nil
    }

    var modifiedAtLocally: NSDate? {
        return self[NoteFields.modifiedAtLocally] as? NSDate
    }
}

extension Note {
    var cloudKitRecord: CKRecord {
        var ckRecord: CKRecord!

        switch self.recordArchive {
        case .some(let archive):
            ckRecord = archive.ckRecorded!
        case .none:
            let zoneID = CKRecordZone.ID(zoneName: "Notes", ownerName: CKCurrentUserDefaultName)
            let id = CKRecord.ID(
                recordName: UUID().uuidString,
                zoneID: zoneID
            )
            ckRecord = CKRecord(recordType: RemoteStorageSerevice.Records.note, recordID: id)
            self.recordID = ckRecord.recordID
        }
        if let content = content {
            ckRecord[Fields.content] = content as CKRecordValue
        }
        if let location = location as? CLLocation {
            ckRecord[Fields.location] = location
        }

        if !isShared {
            if let tags = tags {
                ckRecord[Fields.tags] = tags as CKRecordValue
            }
            ckRecord[Fields.isRemoved] = (isRemoved ? 1 : 0) as CKRecordValue
            //  ckRecord[Fields.isLocked] = (isLocked ? 1 : 0) as CKRecordValue
            ckRecord[Fields.isPinned] = isPinned as CKRecordValue
        }

        ckRecord[Fields.createdAtLocally] = createdAt
        ckRecord[Fields.modifiedAtLocally] = modifiedAt

        return ckRecord
    }

    var remoteID: CKRecord.ID? {
        return recordID as? CKRecord.ID
    }
}
