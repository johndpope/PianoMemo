//
//  NoteUploader.swift
//  Piano
//
//  Created by hoemoon on 20/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit

final class NoteUploader: ElementChangeProcessor {
    var processorType: ChangeProcessorType = .upload
    var retriedErrorCodes = [Int]()
    var elementsInProgress = InProgressTracker<Note>()

    var predicateForLocallyTrackedElements: NSPredicate {
        let inserted = NSPredicate(format: "%K == NULL", NoteKey.recordID.rawValue)
        let updated = NSPredicate(format: "%K == true", NoteKey.markedForUploadReserved.rawValue)
        return NSCompoundPredicate(orPredicateWithSubpredicates: [inserted, updated])
    }
}
