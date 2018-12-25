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

    init(context: NSManagedObjectContext,
         needByPass: Bool = false) {

        self.context = context
        self.needBypass = needByPass
        super.init()
    }

    override func main() {
        guard let changeProvider = zoneChangeProvider else { return }
        changeProvider.newRecords.forEach { wrapper in
            let isMine = wrapper.0
            let record = wrapper.1

            let note = Note.fetch(in: context) { request in
                request.predicate = Note.predicateForRecordID(record.recordID)
                request.returnsObjectsAsFaults = false
            }.first

            switch note {
            case .some(let note):
                if let local = note.modifiedAt,
                    let remote = record[Field.modifiedAtLocally] as? NSDate,
                    (local as Date) < (remote as Date) {

                    context.update(origin: note, with: record, isMine: isMine)
                    popDetailIfNeeded(recordID: record.recordID)
                }
            case .none:
                context.create(with: record, isMine: isMine)
            }
        }

        changeProvider.removedReocrdIDs.forEach { recordID in
            context.performChanges { [weak self] in
                guard let self = self else { return }
                let note = Note.fetch(in: self.context) { request in
                    request.predicate = Note.predicateForRecordID(recordID)
                }.first
                note?.markForLocalDeletion()
                self.popDetailIfNeeded(recordID: recordID)
            }
        }
        if needBypass {
            NotificationCenter.default.post(name: .bypassList, object: nil)
        }
    }
}

extension HandleZoneChangeOperation {
    private func popDetailIfNeeded(recordID: CKRecord.ID) {
        guard let editing = EditingTracker.shared.editingNote,
            editing.recordID == recordID else { return }
        if editing.isRemoved || editing.markedForDeletionDate != nil {
            NotificationCenter.default
                .post(name: .popDetail, object: nil)
            return
        }
        NotificationCenter.default
            .post(name: .resolveContent, object: nil)
    }
}
