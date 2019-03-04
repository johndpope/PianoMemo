//
//  NoteUploader.swift
//  Piano
//
//  Created by hoemoon on 20/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

final class NoteUploader: ElementChangeProcessor {
    var processorType: ChangeProcessorType = .upload
    var retriedErrorCodes = [Int]()
    var elementsInProgress = InProgressTracker<Note>()

    var predicateForLocallyTrackedElements: NSPredicate {
        return NSPredicate(format: "%K == true", NoteKey.markedForUploadReserved.rawValue)
    }
}
