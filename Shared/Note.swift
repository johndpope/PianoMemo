//
//  Note.swift
//  Piano
//
//  Created by hoemoon on 20/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData
import CloudKit

public class Note: NSManagedObject {
    @NSManaged public var content: String?
    @NSManaged public var createdAt: NSDate?
    @NSManaged public var createdBy: NSObject?
    @NSManaged public var isMine: Bool
    @NSManaged public var isPinned: Int64
    @NSManaged public var isRemoved: Bool
    @NSManaged public var isShared: Bool
    @NSManaged public var location: NSObject?
    @NSManaged public var modifiedAt: NSDate?
    @NSManaged public var modifiedBy: NSObject?
    @NSManaged public var recordArchive: NSData?
    @NSManaged public var recordID: NSObject?
    @NSManaged public var tags: String?

    @NSManaged public var markForRemotePurge: Bool
    @NSManaged public var markForLocalPurge: NSDate?
}

extension Note: ReserveUploadable {
    @NSManaged public var markedForUploadReserved: Bool
}

extension Note {
    enum MarkerKey: String {
        case markedForUploadReserved
        case markForRemotePurge
        case markForLocalPurge
        case recordID
    }

    private var titles: (String, String) {
        return (content ?? "").titles
    }
    var title: String {
        return titles.0
    }

    var subTitle: String {
        return titles.1
    }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Note> {
        return NSFetchRequest<Note>(entityName: "Note")
    }

    static func insert(
        into moc: NSManagedObjectContext,
        content: String,
        tags: String) {

        let note: Note = moc.insertObject()
        note.content = content
        note.tags = tags
        note.createdAt = Date() as NSDate
        note.modifiedAt = Date() as NSDate
        note.isMine = true
        note.isPinned = 0
        note.isRemoved = false
    }
}

extension String {
    var titles: (String, String) {
        var strArray = self.split(separator: "\n")
        guard strArray.count != 0 else {
            return ("Untitled".loc, "No text".loc)
        }
        let titleSubstring = strArray.removeFirst()
        let titleString = String(titleSubstring)
        let title = titleString.removeForm()

        var subTitleString: String = ""
        while true {
            guard strArray.count != 0 else { break }

            let pieceSubString = strArray.removeFirst()
            let pieceString = String(pieceSubString)
            let piece = pieceString.removeForm()
            subTitleString.append(piece)
            let titleLimit = 50
            if subTitleString.count > titleLimit {
                break
            }
        }

        return (title, subTitleString.count != 0 ? subTitleString : "No text".loc)
    }
}
