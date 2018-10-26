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
    private let editingNote: Note?
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
         editingNote: Note? = nil,
         needByPass: Bool = false) {

        self.backgroundContext = backgroundContext
        self.mainContext = mainContext
        self.needBypass = needByPass
        self.editingNote = editingNote
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

                // 현재 편집하는 노트가 업데이트 된 경우에 노티 날리기
                if let editing = editingNote, editing.objectID == note.objectID {
                    mainContext.saveIfNeeded()
                    NotificationCenter.default
                        .post(name: .resolveContent, object: nil)
                }
            } else {
                let empty = Note(context: backgroundContext)
                notlify(from: record, to: empty, isMine: isMine)
            }
        }
        mainContext.saveIfNeeded()

        changeProvider.removedReocrdIDs.forEach { recordID in
            mainContext.performAndWait {
                if let note = mainContext.note(with: recordID) {
                    mainContext.delete(note)
                }
            }
        }
        if needBypass {
            NotificationCenter.default.post(name: .bypassList, object: nil)
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
            note.createdAt = record[Field.createdAtLocally] as? Date
            note.modifiedAt = record[Field.modifiedAtLocally] as? Date

            // for lower version
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
