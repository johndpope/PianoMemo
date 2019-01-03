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
    var retriedErrorCode = [Int]()

    var elementsInProgress = InProgressTracker<Note>()

    func processChangedLocalElements(_ elements: [Note], in context: ChangeProcessorContext) {
        guard elements.count > 0 else { return }
        context.remote.upload(elements, savePolicy: .ifServerRecordUnchanged) { saved, _, error in
            context.perform { [weak self] in
                guard let self = self else { return }
                if let error = error {
                    self.elementsInProgress.markObjectsAsComplete(elements)
                    self.handleError(
                        context: context,
                        uploads: elements,
                        removes: [],
                        error: error
                    )
                    return
                }

                guard let saved = saved else { return }
                for note in elements {
                    guard let record = saved.first(
                        where: { note.modifiedAt == $0.modifiedAtLocally }) else { continue }
                    note.recordID = record.recordID
                    note.recordArchive = record.archived
                    note.resolveUploadReserved()
                }
                context.delayedSaveOrRollback()
                self.elementsInProgress.markObjectsAsComplete(elements)
            }
        }
    }

    var predicateForLocallyTrackedElements: NSPredicate {
        let inserted = NSPredicate(format: "%K == NULL", NoteKey.recordID.rawValue)
        let updated = NSPredicate(format: "%K == true", NoteKey.markedForUploadReserved.rawValue)
        return NSCompoundPredicate(orPredicateWithSubpredicates: [inserted, updated])
    }
}
