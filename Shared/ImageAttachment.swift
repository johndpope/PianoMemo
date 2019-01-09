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

public class ImageAttachment: NSManagedObject {
    @NSManaged public var localID: String?
    @NSManaged public var imageData: NSData?
    @NSManaged public var isMine: Bool

    @NSManaged public var modifiedAt: NSDate?
    @NSManaged public var createdAt: NSDate?

    @NSManaged public var recordArchive: NSData?
    @NSManaged public var recordID: NSObject?
}

extension ImageAttachment: UploadReservable {
    @NSManaged public var markedForUploadReserved: Bool
}

extension ImageAttachment: RemoteDeletable {
    @NSManaged public var markedForRemoteDeletion: Bool
}

extension ImageAttachment: DelayedDeletable {
    @NSManaged public var markedForDeletionDate: NSDate?
}

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
        image.createdAt = Date() as NSDate
        image.modifiedAt = Date() as NSDate
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
