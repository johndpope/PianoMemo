//
//  FolderRemover.swift
//  Piano
//
//  Created by hoemoon on 17/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

final class FolderRemover: ElementChangeProcessor {
    var processorType: ChangeProcessorType = .remove
    var retriedErrorCodes = [Int]()
    var elementsInProgress = InProgressTracker<Folder>()

    var predicateForLocallyTrackedElements: NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "%K == true", SyncFlag.markedForRemoteDeletion.rawValue),
            NSPredicate(format: "%K == NULL", SyncFlag.markedForDeletionDate.rawValue)
        ])
    }
}
