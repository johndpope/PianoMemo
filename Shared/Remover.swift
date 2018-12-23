//
//  Remover.swift
//  Piano
//
//  Created by hoemoon on 20/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

final class RemoteRemover: ElementChangeProcessor {
    func processChangedLocalElements(_ elements: [Note], in context: ChangeProcessorContext) {
    }

    var predicateForLocallyTrackedElements: NSPredicate {
        return NSPredicate(value: true)
    }

    var elementsInProgress = InProgressTracker<Note>()

    func setup(for context: ChangeProcessorContext) {
    }

    func processRemoteChanges<T>(_ changes: [RemoteRecordChange<T>], in context: ChangeProcessorContext, completion: () -> Void) where T : RemoteRecord {
    }

    func fetchLatestRemoteRecords(in context: ChangeProcessorContext) {
    }


}
