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
}

extension Folder {
    static func insert(into moc: NSManagedObjectContext) -> Folder {
        let folder: Folder = moc.insertObject()
        folder.createdAt = Date() as NSDate
        return folder
    }
}

extension Folder: Managed {}
