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
    private weak var recordHandler: RecordHandlable?
    private weak var errorHandler: FetchErrorHandlable?
    private let scope: CKDatabase.Scope
    private let needBypass: Bool
    private var completion: ((Bool) -> Void)?
    private var zoneChangeProvider: ZoneChangeProvider? {
        if let provider = dependencies
            .filter({$0 is ZoneChangeProvider})
            .first as? ZoneChangeProvider {
            return provider
        }
        return nil
    }

    init(scope: CKDatabase.Scope,
         recordHandler: RecordHandlable,
         errorHandler: FetchErrorHandlable,
         needByPass: Bool = false,
         completion: @escaping (Bool) -> Void) {

        self.scope = scope
        self.recordHandler = recordHandler
        self.errorHandler = errorHandler
        self.needBypass = needByPass
        self.completion = completion
        super.init()
    }

    override func main() {
        guard let changeProvider = zoneChangeProvider,
            let recordHandler = recordHandler,
            let errorHandler = errorHandler else { return }

        if let error = changeProvider.error {
            errorHandler.handleError(error: error) { [weak self] in
                guard let self = self else { return }
                self.executeCompletion()
                return
            }
        }

        changeProvider.newRecords.forEach { wrapper in
            let isMine = wrapper.0
            let record = wrapper.1

            recordHandler.createOrUpdate(record: record, isMine: isMine) { [weak self] in
                guard let self = self else { return }
                self.popDetailIfNeeded(recordHandler: recordHandler, recordID: record.recordID)
                self.executeCompletion()
            }
        }

        changeProvider.removedReocrdIDs.forEach { recordID in
            recordHandler.remove(recordID: recordID) { [weak self] in
                guard let self = self else { return }
                self.popDetailIfNeeded(recordHandler: recordHandler, recordID: recordID)
                self.executeCompletion()
            }
        }
        if changeProvider.newRecords.count == 0, changeProvider.removedReocrdIDs.count == 0 {
            self.executeCompletion()
        }
        if needBypass {
            NotificationCenter.default.post(name: .bypassList, object: nil)
        }
    }
}

extension HandleZoneChangeOperation {
    private func popDetailIfNeeded(recordHandler: RecordHandlable, recordID: CKRecord.ID) {
        recordHandler.backgroundContext.performAndWait {
            guard let editing = EditingTracker.shared.editingNote,
                let note = recordHandler.backgroundContext.object(with: editing.objectID) as? Note,
                note.recordID == recordID else { return }

            if note.isRemoved || note.markedForDeletionDate != nil {
                NotificationCenter.default.post(name: .popDetail, object: nil)
            } else {
                NotificationCenter.default.post(name: .resolveContent, object: nil)
            }
        }
    }

    private func executeCompletion() {
        if let completion = completion {
            completion(true)
            self.completion = nil
            if self.scope == .private {
                NotificationCenter.default.post(name: .didFinishHandleZoneChange, object: nil)
            }
        }
    }
}
