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
    enum FolderType: Int {
        case custom
        case all
        case locked
        case removed
    }

//    var fetchRequest: NSFetchRequest<Note>? {
//        guard let folderType = FolderType(rawValue: Int(Int64(self.type))) else { return nil }
//        let request: NSFetchRequest<Note> = Note.fetchRequest()
//        let modifiedAt = NSSortDescriptor(key: "modifiedAt", ascending: false)
//        request.fetchBatchSize = 20
//        request.sortDescriptors = [modifiedAt]
//        let common = NSCompoundPredicate(andPredicateWithSubpredicates: [
//            Note.notMarkedForLocalDeletionPredicate,
//            Note.notMarkedForRemoteDeletionPredicate
//            ])
//        switch folderType {
//        case .all:
//            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
//                NSPredicate(format: "isRemoved == false"), common
//                ])
//        case .custom:
//            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
//                NSPredicate(format: "isRemoved == false"),
//                NSPredicate(format: "folder == %@", self),
//                common
//                ])
//        case .locked:
//            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
//                NSPredicate(format: "isRemoved == false"),
//                NSPredicate(format: "isLocked == false"),
//                common
//                ])
//        case .removed:
//            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
//                NSPredicate(format: "isRemoved == true"),
//                common
//                ])
//        }
//        return request
//    }

    static func insert(
        into moc: NSManagedObjectContext,
        type: FolderType,
        needUpload: Bool = true) -> Folder {

        let folder: Folder = moc.insertObject()
        let id = UUID().uuidString
        folder.localID = id
        folder.createdAt = Date()
        folder.modifiedAt = Date()
        folder.isMine = true
        folder.type = Int64(type.rawValue)

        if needUpload {
            folder.markUploadReserved()
        }

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
        let order = NSSortDescriptor(key: "order", ascending: false)
        request.predicate = NSPredicate(value: true)
        request.fetchBatchSize = 20
        request.sortDescriptors = [order]
        return request
    }
}
