//
//  Folder.swift
//  Piano
//
//  Created by hoemoon on 10/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import CoreData

public class Folder: NSManagedObject {
    @NSManaged public var name: String?
    @NSManaged public var createdAt: NSDate?
    @NSManaged public var notes: Set<Note>
    @NSManaged public var type: Int64

    enum FolderType: Int {
        case custom
        case all
        case locked
        case removed
    }

    var fetchRequest: NSFetchRequest<Note>? {
        guard let folderType = FolderType(rawValue: Int(Int64(self.type))) else { return nil }
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        let modifiedAt = NSSortDescriptor(key: "modifiedAt", ascending: false)
        request.fetchBatchSize = 20
        request.sortDescriptors = [modifiedAt]
        let common = NSCompoundPredicate(andPredicateWithSubpredicates: [
            Note.notMarkedForLocalDeletionPredicate,
            Note.notMarkedForRemoteDeletionPredicate
        ])
        switch folderType {
        case .all:
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "isRemoved == false"), common
            ])
        case .custom:
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "isRemoved == false"),
                NSPredicate(format: "folder == %@", self),
                common
            ])
        case .locked:
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "isRemoved == false"),
                NSPredicate(format: "isLocked == false"),
                common
            ])
        case .removed:
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "isRemoved == true"),
                common
            ])
        }
        return request
    }
}

extension Folder {
    static func insert(into moc: NSManagedObjectContext, type: FolderType) -> Folder {
        let folder: Folder = moc.insertObject()
        folder.createdAt = Date() as NSDate
        folder.type = Int64(type.rawValue)
        return folder
    }
}

extension Folder: Managed {}
