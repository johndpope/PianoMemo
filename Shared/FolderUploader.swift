//
//  FolderUploader.swift
//  Piano
//
//  Created by hoemoon on 17/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

final class FolderUploder: ElementChangeProcessor {
    var processorType: ChangeProcessorType = .upload
    var retriedErrorCodes = [Int]()
    var elementsInProgress = InProgressTracker<Folder>()

    var predicateForLocallyTrackedElements: NSPredicate {
        return NSPredicate(format: "%K == true", SyncFlag.markedForUploadReserved.rawValue)
    }
}
