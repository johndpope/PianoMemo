//
//  HandlerZoneChangeOperation.swift
//  Piano
//
//  Created by hoemoon on 24/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

class HandleZoneChangeOperation: Operation {
    private let backgroundContext: NSManagedObjectContext
    private let mainContext: NSManagedObjectContext
    private let needBypass: Bool
    private var zoneChangeProvider: ZoneChangeProvider? {
        if let provider = dependencies
            .filter({$0 is ZoneChangeProvider})
            .first as? ZoneChangeProvider {
            return provider
        }
        return nil
    }

    init(backgroundContext: NSManagedObjectContext,
         mainContext: NSManagedObjectContext,
         needByPass: Bool = false) {

        self.backgroundContext = backgroundContext
        self.mainContext = mainContext
        self.needBypass = needByPass
        super.init()
    }

    override func main() {
        guard let changeProvider = zoneChangeProvider else {
            return
        }
        changeProvider.newRecords.forEach { wrapper in
            let record = wrapper.1
            let isMine = wrapper.0

            if let note = backgroundContext.note(with: record.recordID) {
                notlify(from: record, to: note, isMine: isMine)
            } else {
                let empty = Note(context: backgroundContext)
                notlify(from: record, to: empty, isMine: isMine)
            }
        }

        changeProvider.removedReocrdIDs.forEach { recordID in
            mainContext.performAndWait {
                if let note = mainContext.note(with: recordID) {
                    mainContext.delete(note)
                }
            }
        }
        mainContext.saveIfNeeded()
        
        if needBypass {
            NotificationCenter.default.post(name: .bypassList, object: nil)
        } else {
            NotificationCenter.default
                .post(name: .resolveContent, object: nil)
        }
    }

    private func notlify(from record: CKRecord, to note: Note, isMine: Bool) {
        typealias Field = RemoteStorageSerevice.NoteFields
        backgroundContext.performAndWait {
            // update custom fields
            note.content = record[Field.content] as? String
            note.recordID = record.recordID

            note.createdBy = record.creatorUserRecordID
            note.modifiedBy = record.lastModifiedUserRecordID
            if note.createdAt == nil {
                note.createdAt = record.creationDate
            }
            if note.modifiedAt == nil {
                note.modifiedAt = record.modificationDate
            }
            note.location = record[Field.location] as? CLLocation
            note.isMine = isMine
            note.recordArchive = record.archived
            if let content = note.content {
                let titles = content.titles
                note.title = titles.0
                note.subTitle = titles.1
            }

            if let _ = record.share {
                note.isShared = true
            } else {
                note.isShared = false
                note.isRemoved = (record[Field.isRemoved] as? Int ?? 0) == 1 ? true : false
                note.isLocked = (record[Field.isLocked] as? Int ?? 0) == 1 ? true : false
                note.tags = record[Field.tags] as? String
            }
            backgroundContext.saveIfNeeded()
        }
    }
}
