//
//  InProgressTracker.swift
//  Piano
//
//  Created by hoemoon on 20/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData

final class InProgressTracker<O: NSManagedObject> where O: Managed {
    fileprivate var objectsInProgress = Set<O>()

    /// Return those objects from the given `objects` that are not yet in progress.
    /// These new objects are then marked as being in progress.
    func objectsToProcess(from objects: [O]) -> [O] {
        let added = objects.filter { !objectsInProgress.contains($0) }
        objectsInProgress.formUnion(added)
        return added
    }

    /// Marks the given objects as being complete
    func markObjectsAsComplete(_ objects: [O]) {
        objectsInProgress.subtract(objects)
    }
}
