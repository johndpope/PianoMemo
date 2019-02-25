//
//  Folder.swift
//  Piano
//
//  Created by hoemoon on 10/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import CoreData
import CloudKit

extension Folder: Managed, UploadReservable, RemoteDeletable, DelayedDeletable {}

extension Folder {
    static func insert(
        into moc: NSManagedObjectContext) -> Folder {

        let folder: Folder = moc.insertObject()
        let id = UUID().uuidString
        folder.localID = id
        folder.createdAt = Date()
        folder.modifiedAt = Date()
        folder.isMine = true

        let zoneID = CKRecordZone.ID(zoneName: "Notes", ownerName: CKCurrentUserDefaultName)
        let ckRecordID = CKRecord.ID(
            recordName: id,
            zoneID: zoneID
        )
        folder.recordArchive = CKRecord(recordType: Record.folder, recordID: ckRecordID).archived
        return folder
    }

    static var listRequest: NSFetchRequest<Folder> {
        let request: NSFetchRequest<Folder> = Folder.fetchRequest()
        let order = NSSortDescriptor(key: "order", ascending: true)
        request.predicate = NSPredicate(value: true)
        request.fetchBatchSize = 20
        request.sortDescriptors = [order]
        return request
    }
}
