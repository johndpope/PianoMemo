//
//  InProgressTracker.swift
//  Piano
//
//  Created by hoemoon on 20/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData

/// 클라우드킷에 중복된 요청을 하는 것을 막도록 현재 진행 중인 객체들에 대해 추적합니다.
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
