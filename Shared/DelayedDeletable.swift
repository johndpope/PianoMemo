//
//  DelayedDeletable.swift
//  Piano
//
//  Created by hoemoon on 23/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData

private let MarkedForDeletionDateKey = "markedForDeletionDate"

protocol DelayedDeletable: class {
    var changedForDelayedDeletion: Bool { get }
    var markedForDeletionDate: Date? { get set }
    func markForLocalDeletion()
}

extension DelayedDeletable {
    static var notMarkedForLocalDeletionPredicate: NSPredicate {
        return NSPredicate(format: "%K == NULL", MarkedForDeletionDateKey)
    }
}

extension DelayedDeletable where Self: NSManagedObject {
    var changedForDelayedDeletion: Bool {
        return changedValue(forKey: MarkedForDeletionDateKey) as? Date != nil
    }

    func markForLocalDeletion() {
        guard isFault || markedForDeletionDate == nil else { return }
        markedForDeletionDate = Date()
    }
}

private let DeletionAgeBeforePermanentlyDeletingObjects = TimeInterval(2 * 60)

extension NSManagedObjectContext {
    func batchDeleteObjectsMarkedForLocalDeletion() {

    }
}

extension DelayedDeletable where Self: NSManagedObject, Self: Managed {
    fileprivate static func batchDeleteObjectsMarkedForLocalDeletionInContext(_ managedObjectContext: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName)
        let cutoff = Date(timeIntervalSinceNow: -DeletionAgeBeforePermanentlyDeletingObjects)
        fetchRequest.predicate = NSPredicate(format: "%K < %@", MarkedForDeletionDateKey, cutoff as NSDate)
        let batchRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchRequest.resultType = .resultTypeStatusOnly
        try! managedObjectContext.execute(batchRequest)
    }
}
