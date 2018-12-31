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
    private let recordHandler: RecordHandlable
    private let needBypass: Bool
    private var zoneChangeProvider: ZoneChangeProvider? {
        if let provider = dependencies
            .filter({$0 is ZoneChangeProvider})
            .first as? ZoneChangeProvider {
            return provider
        }
        return nil
    }

    init(recordHandler: RecordHandlable,
         needByPass: Bool = false) {

        self.recordHandler = recordHandler
        self.needBypass = needByPass
        super.init()
    }

    override func main() {
        guard let changeProvider = zoneChangeProvider else { return }
        changeProvider.newRecords.forEach { wrapper in
            let isMine = wrapper.0
            let record = wrapper.1

            recordHandler.createOrUpdate(record: record, isMine: isMine) {
                [weak self] in
                guard let self = self else { return }
                self.popDetailIfNeeded(recordID: record.recordID)
            }
        }

        changeProvider.removedReocrdIDs.forEach { recordID in
            recordHandler.remove(recordID: recordID) {
                [weak self] in
                guard let self = self else { return }
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
