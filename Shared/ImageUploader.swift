//
//  ImageUploader.swift
//  Piano
//
//  Created by hoemoon on 08/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

final class ImageUploader: ElementChangeProcessor {
    var retriedErrorCodes = [Int]()
    var elementsInProgress = InProgressTracker<ImageAttachment>()

    var predicateForLocallyTrackedElements: NSPredicate {
        let inserted = NSPredicate(format: "%K == NULL", ImageKey.recordID.rawValue)
        let updated = NSPredicate(format: "%K == true", ImageKey.markedForUploadReserved.rawValue)
        return NSCompoundPredicate(orPredicateWithSubpredicates: [inserted, updated])
    }

    func processChangedLocalElements(_ elements: [ImageAttachment], in context: ChangeProcessorContext) {
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
                for image in elements {
                    guard let record = saved.first(
                        where: { image.modifiedAt == $0.modifiedAtLocally }) else { continue }
                    image.recordID = record.recordID
                    image.recordArchive = record.archived
                    image.resolveUploadReserved()
                }
                context.delayedSaveOrRollback()
                self.elementsInProgress.markObjectsAsComplete(elements)
            }
        }
    }
}
