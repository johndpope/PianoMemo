//
//  RemoteRemover.swift
//  Piano
//
//  Created by hoemoon on 20/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

final class RemoteRemover: ElementChangeProcessor {
    var elementsInProgress = InProgressTracker<Note>()

    func processChangedLocalElements(_ elements: [Note], in context: ChangeProcessorContext) {
        guard elements.count > 0 else { return }

        let allObjects = Set(elements)
        let localOnly = allObjects.filter { $0.remoteID == nil }
        let objectsToDeleteRemotely = allObjects.subtracting(localOnly)

        deleteLocally(localOnly, context: context)
        deleteRemotely(objectsToDeleteRemotely, context: context)
    }

    func setup(for context: ChangeProcessorContext) {
    }

    func processRemoteChanges<T>(_ changes: [RemoteRecordChange<T>], in context: ChangeProcessorContext, completion: () -> Void) where T : RemoteRecord {
    }

    func fetchLatestRemoteRecords(in context: ChangeProcessorContext) {
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

        context.remote.remove(Array(deletions)) { _, ids, _ in
            context.perform { [weak self] in
                // TODO: error handling
                guard let self = self, let ids = ids else { return }
                let deletedIDs = Set(ids)
                let toBeDeleted = deletions.filter { deletedIDs.contains($0.remoteID!) }
                self.deleteLocally(toBeDeleted, context: context)
                context.delayedSaveOrRollback()
            }
        }
    }
}
