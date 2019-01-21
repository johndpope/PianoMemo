//
//  ImageAttachment.swift
//  Piano
//
//  Created by hoemoon on 08/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import CoreData
import CloudKit

typealias ImageKey = ImageAttachment.LocalKey

extension ImageAttachment: UploadReservable, RemoteDeletable, DelayedDeletable {}

extension ImageAttachment {
    enum LocalKey: String {
        case localID
        case imageData

        case recordID
        case markedForUploadReserved
        case markedForRemoteDeletion
        case markedForDeletionDate
    }

    static func insert(into moc: NSManagedObjectContext) -> ImageAttachment {
        let image: ImageAttachment = moc.insertObject()
        let id = UUID().uuidString
        image.localID = id
        image.createdAt = Date()
        image.modifiedAt = Date()
        image.isMine = true

        let zoneID = CKRecordZone.ID(zoneName: "Notes", ownerName: CKCurrentUserDefaultName)
        let ckRecordID = CKRecord.ID(
            recordName: id,
            zoneID: zoneID
        )
        image.recordArchive = CKRecord(recordType: Record.image, recordID: ckRecordID).archived
        return image
    }

    static func predicateForRecordID(_ id: CKRecord.ID) -> NSPredicate {
        return NSPredicate(format: "%K == %@", ImageKey.recordID.rawValue, id as CVarArg)
    }
}

extension ImageAttachment: Managed {}
