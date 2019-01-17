//
//  ImageRemover.swift
//  Piano
//
//  Created by hoemoon on 08/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

final class ImageRemover: ElementChangeProcessor {
    var processorType: ChangeProcessorType = .remove
    var retriedErrorCodes = [Int]()
    var elementsInProgress = InProgressTracker<ImageAttachment>()

    var predicateForLocallyTrackedElements: NSPredicate {
        let marked = ImageAttachment.markedForRemoteDeletionPredicate
        let notDeleted = ImageAttachment.notMarkedForLocalDeletionPredicate
        return NSCompoundPredicate(andPredicateWithSubpredicates: [marked, notDeleted])
    }
}
