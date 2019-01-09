//
//  ImageRemover.swift
//  Piano
//
//  Created by hoemoon on 08/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

final class ImageRemover: ElementChangeProcessor {
    var retriedErrorCodes = [Int]()

    var elementsInProgress = InProgressTracker<ImageAttachment>()

    func processChangedLocalElements(_ elements: [ImageAttachment], in context: ChangeProcessorContext) {
        guard elements.count > 0 else { return }

        let allObjects = Set(elements)
        let localOnly = allObjects.filter { $0.remoteID == nil }
        let objectsToDeleteRemotely = allObjects.subtracting(localOnly)

        deleteLocally(localOnly, context: context)
        deleteRemotely(objectsToDeleteRemotely, context: context)
    }

    var predicateForLocallyTrackedElements: NSPredicate {
        let marked = ImageAttachment.markedForRemoteDeletionPredicate
        let notDeleted = ImageAttachment.notMarkedForLocalDeletionPredicate
        return NSCompoundPredicate(andPredicateWithSubpredicates: [marked, notDeleted])
    }

}

extension ImageRemover {
    fileprivate func deleteLocally(_ deletions: Set<ImageAttachment>, context: ChangeProcessorContext) {
        context.perform {
            deletions.forEach { $0.markForLocalDeletion() }
        }
    }

    fileprivate func deleteRemotely(_ deletions: Set<ImageAttachment>, context: ChangeProcessorContext) {
        context.remote.remove(Array(deletions), savePolicy: .ifServerRecordUnchanged) { _, ids, error in
            context.perform { [weak self] in
                guard let self = self, error == nil else { return }
                if let error = error {
                    self.elementsInProgress.markObjectsAsComplete(Array(deletions))
                    self.handleError(
                        context: context,
                        uploads: [],
                        removes: Array(deletions),
                        error: error
                    )
                    return
                }
                guard let ids = ids else { return }
                let deletedIDs = Set(ids)
                let toBeDeleted = deletions.filter { deletedIDs.contains($0.remoteID!) }
                self.deleteLocally(toBeDeleted, context: context)
                context.delayedSaveOrRollback()
                self.elementsInProgress.markObjectsAsComplete(Array(deletions))
            }
        }
    }
}
