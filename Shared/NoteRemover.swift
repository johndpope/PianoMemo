//
//  NoteRemover.swift
//  Piano
//
//  Created by hoemoon on 20/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

final class NoteRemover: ElementChangeProcessor {
    var processorType: ChangeProcessorType = .remove
    var retriedErrorCodes = [Int]()
    var elementsInProgress = InProgressTracker<Note>()

    var predicateForLocallyTrackedElements: NSPredicate {
        let marked = Note.markedForRemoteDeletionPredicate
        let notDeleted = Note.notMarkedForLocalDeletionPredicate
        return NSCompoundPredicate(andPredicateWithSubpredicates: [marked, notDeleted])
    }
}
