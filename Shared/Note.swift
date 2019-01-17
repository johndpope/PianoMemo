//
//  Note.swift
//  Piano
//
//  Created by hoemoon on 20/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData
import CloudKit

typealias NoteKey = Note.LocalKey

extension Note: UploadReservable, RemoteDeletable, DelayedDeletable {}

extension Note {
    enum LocalKey: String {
        case markedForUploadReserved
        case markedForRemoteDeletion
        case markedForDeletionDate
        case recordID
        case isRemoved
        case modifiedAt
        case isShared
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

    static func insert(
        into moc: NSManagedObjectContext,
        content: String = "",
        tags: String = "",
        needUpload: Bool = true) -> Note {

        let note: Note = moc.insertObject()
        note.content = content
        note.tags = tags
        note.createdAt = Date()
        note.modifiedAt = Date()
        note.isMine = true
        note.isPinned = 0
        note.isRemoved = false
        if needUpload {
            note.markUploadReserved()
        }
        let zoneID = CKRecordZone.ID(zoneName: "Notes", ownerName: CKCurrentUserDefaultName)
        let id = CKRecord.ID(
            recordName: UUID().uuidString,
            zoneID: zoneID
        )
        note.recordArchive = CKRecord(recordType: Record.note, recordID: id).archived

        return note
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

extension Note {
    static var predicateForTrash: NSPredicate {
        let isRemoved = NSPredicate(format: "%K == true", NoteKey.isRemoved.rawValue)
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            isRemoved,
            notMarkedForRemoteDeletionPredicate,
            notMarkedForLocalDeletionPredicate]
        )
    }

    static var predicateForMerge: NSPredicate {
        let notRemoved = NSPredicate(format: "%K == false", NoteKey.isRemoved.rawValue)
        let notShared = NSPredicate(format: "%K == false", NoteKey.isShared.rawValue)
        return NSCompoundPredicate(andPredicateWithSubpredicates: [notRemoved, notShared, Note.notMarkedForLocalDeletionPredicate])
    }

    static var trashRequest: NSFetchRequest<Note> {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: NoteKey.modifiedAt.rawValue, ascending: false)
        request.predicate = Note.predicateForTrash
        request.sortDescriptors = [sort]
        return request
    }

    static var predicateForMaster: NSPredicate {
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "isRemoved == false"),
            Note.notMarkedForLocalDeletionPredicate,
            Note.notMarkedForRemoteDeletionPredicate
            ]
        )
    }

    static var masterRequest: NSFetchRequest<Note> {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        let date = NSSortDescriptor(key: "modifiedAt", ascending: false)
        let pinned = NSSortDescriptor(key: "isPinned", ascending: false)
        request.predicate = predicateForMaster
        request.fetchBatchSize = 20
        request.sortDescriptors = [pinned, date]
        return request
    }
    
    static var noteCollectionRequest: NSFetchRequest<Note> {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        let date = NSSortDescriptor(key: "modifiedAt", ascending: false)
        let pinned = NSSortDescriptor(key: "isPinned", ascending: false)
        request.predicate = predicateForMaster
        request.fetchBatchSize = 50
        request.sortDescriptors = [pinned, date]
        return request
    }

    static func allfetchRequest() -> NSFetchRequest<Note> {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
        request.predicate = NSPredicate(value: true)
        request.sortDescriptors = [sort]
        return request
    }

    static func predicateForRecordID(_ id: CKRecord.ID) -> NSPredicate {
        return NSPredicate(format: "%K == %@", NoteKey.recordID.rawValue, id as CVarArg)
    }
}
