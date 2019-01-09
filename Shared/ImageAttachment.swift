//
//  ImageAttachment.swift
//  Piano
//
//  Created by hoemoon on 08/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import CoreData

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
        image.createdAt = Date() as NSDate
        image.modifiedAt = Date() as NSDate
        image.isMine = true
        return image
    }
}

extension ImageAttachment: Managed {}
