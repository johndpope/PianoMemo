//
//  RemoteUploader.swift
//  Piano
//
//  Created by hoemoon on 20/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit

final class RemoteUploader: ElementChangeProcessor {
    typealias Marker = Note.MarkerKey
    var elementsInProgress = InProgressTracker<Note>()

    func processChangedLocalElements(_ elements: [Note], in context: ChangeProcessorContext) {
        guard elements.count > 0 else { return }
        context.remote.upload(elements) { saved, _, error in
            context.perform { [weak self] in
                guard let self = self, let saved = saved else { return }
                guard !(error?.isPermanent ?? false) else {
                    // TODO: 실패 시 나중에 업로드 하도록 표시 해놓기
                    self.elementsInProgress.markObjectsAsComplete(elements)
                    return
                }

                for note in elements {
                    guard let record = saved.first(
                        where: { note.modifiedAt == $0.modifiedAtLocally }) else { continue }
                    note.recordID = record.recordID
                    note.recordArchive = record.archived
                    note.unmarkUploadReserved()
                }
                context.delayedSaveOrRollback()
                self.elementsInProgress.markObjectsAsComplete(elements)
            }
        }
    }

    func setup(for context: ChangeProcessorContext) {
    }

    func processRemoteChanges<T>(
        _ changes: [RemoteRecordChange<T>],
        in context: ChangeProcessorContext,
        completion: () -> Void) where T :RemoteRecord {
    }

    func fetchLatestRemoteRecords(in context: ChangeProcessorContext) {
    }

    var predicateForLocallyTrackedElements: NSPredicate {
        let inserted = NSPredicate(format: "%K == NULL", Marker.recordID.rawValue)
        let updated = NSPredicate(format: "%K == true", Marker.markedForUploadReserved.rawValue)
        return NSCompoundPredicate(orPredicateWithSubpredicates: [inserted, updated])
    }
}
