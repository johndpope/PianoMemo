//
//  RemoteRemover.swift
//  Piano
//
//  Created by hoemoon on 20/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

final class RemoteRemover: ElementChangeProcessor {
    var retriedErrorCode = [Int]()
    var elementsInProgress = InProgressTracker<Note>()

    func processChangedLocalElements(_ elements: [Note], in context: ChangeProcessorContext) {
        guard elements.count > 0 else { return }

        let allObjects = Set(elements)
        let localOnly = allObjects.filter { $0.remoteID == nil }
        let objectsToDeleteRemotely = allObjects.subtracting(localOnly)

        deleteLocally(localOnly, context: context)
        deleteRemotely(objectsToDeleteRemotely, context: context)
    }

    var predicateForLocallyTrackedElements: NSPredicate {
        let marked = Note.markedForRemoteDeletionPredicate
        let notDeleted = Note.notMarkedForLocalDeletionPredicate
        return NSCompoundPredicate(andPredicateWithSubpredicates: [marked, notDeleted])
    }
}

extension RemoteRemover {
    fileprivate func deleteLocally(_ deletions: Set<Note>, context: ChangeProcessorContext) {
        deletions.forEach { $0.markForLocalDeletion() }
    }

    fileprivate func deleteRemotely(_ deletions: Set<Note>, context: ChangeProcessorContext) {
        context.remote.remove(Array(deletions), savePolicy: .ifServerRecordUnchanged) { _, ids, error in
            context.perform { [weak self] in
                guard let self = self else { return }
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
