//
//  Note_extension.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 30..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import EventKit
import Contacts
import ContactsUI
import Photos
import CloudKit
import DifferenceKit
import MobileCoreServices

extension Note {
    typealias Fields = RemoteStorageSerevice.NoteFields
    func recodify() -> RecordWrapper {
        var record: CKRecord!

        switch recordArchive {
        case .some(let archive):
            if let recorded = archive.ckRecorded {
                record = recorded
            }
        case .none:
            let zoneID = CKRecordZone.ID(zoneName: "Notes", ownerName: CKCurrentUserDefaultName)
            let id = CKRecord.ID(
                recordName: UUID().uuidString,
                zoneID: zoneID
            )
            record = CKRecord(recordType: RemoteStorageSerevice.Records.note, recordID: id)
            // save recordID to persistent storage
            recordID = record.recordID
        }

        // update custom fields
        if let content = content {
            record[Fields.content] = content as CKRecordValue
        }
        if let location = location as? CLLocation {
            record[Fields.location] = location
        }

        if !isShared {
            if let tags = tags {
                record[Fields.tags] = tags as CKRecordValue
            }
            record[Fields.isRemoved] = (isRemoved ? 1 : 0) as CKRecordValue
//            record[Fields.isLocked] = (isLocked ? 1 : 0) as CKRecordValue
            record[Fields.isPinned] = isPinned as CKRecordValue
        }

        record[Fields.createdAtLocally] = createdAt
        record[Fields.modifiedAtLocally] = modifiedAt

        return (self.isMine, record)
    }
}

struct NoteWrapper: Differentiable {
    let note: Note
    let tags: String
    let keyword: String
    var isUpdated: Bool

    init(note: Note,
         keyword: String = "",
         tags: String = "",
         isUpdated: Bool = false) {

        self.note = note
        self.keyword = keyword
        self.tags = tags
        self.isUpdated = isUpdated
    }

    mutating func setUpate() {
        self.isUpdated = true
    }

    var differenceIdentifier: Note {
        return note
    }

    func isContentEqual(to source: NoteWrapper) -> Bool {
        return note == source.note
            && keyword == source.keyword
            && tags == source.tags
            && isUpdated == source.isUpdated
    }
}

extension Note: Differentiable {}

extension Note {
    public static func canHandle(_ session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSString.self)
    }

    var isLocked: Bool {
        if let tags = tags {
            return tags.splitedEmojis.contains("🔒")
        }
        return false
    }
}

extension Note: Managed {
    
}
