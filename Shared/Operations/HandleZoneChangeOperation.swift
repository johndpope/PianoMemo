//
//  HandlerZoneChangeOperation.swift
//  Piano
//
//  Created by hoemoon on 24/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CloudKit
import CoreData
import UIKit

class HandleZoneChangeOperation: Operation {
    private let context: NSManagedObjectContext
    private let needBypass: Bool
    private var zoneChangeProvider: ZoneChangeProvider? {
        if let provider = dependencies
            .filter({$0 is ZoneChangeProvider})
            .first as? ZoneChangeProvider {
            return provider
        }
        return nil
    }

    private var editingNote: Note? {
        return EditingTracker.shared.editingNote
    }

    init(context: NSManagedObjectContext,
         needByPass: Bool = false) {

        self.context = context
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

//            if let note = context.note(with: record.recordID) {
//                notlify(from: record, to: note, isMine: isMine)
//
//                // 현재 편집하는 노트가 업데이트 된 경우에 노티 날리기
//                if let editing = editingNote, editing.objectID == note.objectID {
//
//                    if note.isRemoved {
//                        NotificationCenter.default
//                            .post(name: .popDetail, object: nil)
//                    } else {
//                        NotificationCenter.default
//                            .post(name: .resolveContent, object: nil)
//                    }
//                }
//            } else {
//                let empty = Note(context: context)
//                notlify(from: record, to: empty, isMine: isMine)
//            }

            let notes = Note.fetch(in: context) { request in
                request.predicate = Note.predicateForRecordID(record.recordID)
                request.returnsObjectsAsFaults = false
            }

            if notes.count > 0 {
                let note = notes.first!
                notlify(from: record, to: note, isMine: isMine)
                if let editing = editingNote, editing.recordID == record.recordID {
                    if note.isRemoved {
                        NotificationCenter.default
                            .post(name: .popDetail, object: nil)
                    } else {
                        NotificationCenter.default
                            .post(name: .resolveContent, object: nil)
                    }
                }

            } else {
                let empty = Note(context: context)
                notlify(from: record, to: empty, isMine: isMine)
            }
        }

        changeProvider.removedReocrdIDs.forEach { recordID in
            context.performChanges {
                let notes = Note.fetch(in: self.context) { request in
                    request.predicate = Note.predicateForRecordID(recordID)
                    request.returnsObjectsAsFaults = false
                }
                if notes.count > 0 {
                    if let editing = self.editingNote, editing.recordID == recordID {
                        NotificationCenter.default
                            .post(name: .popDetail, object: nil)
                    }

                    notes.forEach {
                        $0.markForLocalDeletion()
                    }
                }
            }
//            context.performAndWait {
//                if let note = context.note(with: recordID) {
//                    if let editing = editingNote, editing.objectID == note.objectID {
//                        NotificationCenter.default
//                            .post(name: .popDetail, object: nil)
//                    }
//                    note.markForLocalDeletion()
//                }
//            }

        }
        if needBypass {
            NotificationCenter.default.post(name: .bypassList, object: nil)
        }
    }

    private func notlify(from record: CKRecord, to note: Note, isMine: Bool) {
        context.performAndWait {
            note.content = record[Field.content] as? String
            note.recordID = record.recordID

            note.createdAt = record[Field.createdAtLocally] as? NSDate
            note.modifiedAt = record[Field.modifiedAtLocally] as? NSDate

            // for lower version
            if note.createdAt == nil {
                note.createdAt = record.creationDate as NSDate?
            }
            if note.modifiedAt == nil {
                note.modifiedAt = record.modificationDate as NSDate?
            }
            note.location = record[Field.location] as? CLLocation
            note.isMine = isMine
            note.recordArchive = record.archived as NSData
            if let _ = record.share {
                note.isShared = true
            } else {
                note.isShared = false
                note.isRemoved = (record[Field.isRemoved] as? Int ?? 0) == 1 ? true : false
                //                note.isLocked = (record[Field.isLocked] as? Int ?? 0) == 1 ? true : false
                note.isPinned = (record[Field.isPinned] as? Int ?? 0) == 1 ? 1 : 0
                note.tags = record[Field.tags] as? String
            }
            context.saveOrRollback()
        }
    }
}
