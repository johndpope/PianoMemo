//
//  ImageUploader.swift
//  Piano
//
//  Created by hoemoon on 08/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

final class ImageUploader: ElementChangeProcessor {
    var processorType: ChangeProcessorType = .upload
    var retriedErrorCodes = [Int]()
    var elementsInProgress = InProgressTracker<ImageAttachment>()

    var predicateForLocallyTrackedElements: NSPredicate {
        return  NSPredicate(format: "%K == true", ImageKey.markedForUploadReserved.rawValue)
    }
}
