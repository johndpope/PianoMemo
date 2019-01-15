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
        case allNote
        case userCreated
        case prepared
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
