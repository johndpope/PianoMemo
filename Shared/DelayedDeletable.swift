//
//  DelayedDeletable.swift
//  Piano
//
//  Created by hoemoon on 23/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData

protocol DelayedDeletable: class {
//    var changedForDelayedDeletion: Bool { get }
    var markedForDeletionDate: NSDate? { get set }
    func markForLocalDeletion()
}

extension DelayedDeletable {
    static var notMarkedForLocalDeletionPredicate: NSPredicate {
        return NSPredicate(format: "%K == NULL", NoteKey.markedForDeletionDate.rawValue)
    }
}

extension DelayedDeletable where Self: NSManagedObject {
//    var changedForDelayedDeletion: Bool {
//        return changedValue(forKey: Marker.markedForDeletionDate.rawValue) as? Date != nil
//    }

    func markForLocalDeletion() {
        guard isFault || markedForDeletionDate == nil else { return }
        markedForDeletionDate = NSDate()
    }
}

private let DeletionAgeBeforePermanentlyDeletingObjects = TimeInterval(2 * 60)

extension NSManagedObjectContext {
    func batchDeleteObjectsMarkedForLocalDeletion() {
        Note.batchDeleteObjectsMarkedForLocalDeletionInContext(self)
        ImageAttachment.batchDeleteObjectsMarkedForLocalDeletionInContext(self)
        Note.batchDeleteOldTrash(self)
    }
}

extension DelayedDeletable where Self: NSManagedObject, Self: Managed {
    fileprivate static func batchDeleteObjectsMarkedForLocalDeletionInContext(_ managedObjectContext: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName)
        let cutoff = Date(timeIntervalSinceNow: -DeletionAgeBeforePermanentlyDeletingObjects)
        fetchRequest.predicate = NSPredicate(format: "%K < %@", "markedForDeletionDate", cutoff as NSDate)
        let batchRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchRequest.resultType = .resultTypeStatusOnly
        managedObjectContext.perform {
            do {
                try managedObjectContext.execute(batchRequest)
            } catch {
                print(error)
            }
        }
    }

    fileprivate static func batchDeleteOldTrash(_ managedObjectContext: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName)
        fetchRequest.predicate = NSPredicate(format: "isRemoved == true AND modifiedAt < %@", NSDate(timeIntervalSinceNow: -3600 * 24 * 30))
        let batchRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchRequest.resultType = .resultTypeStatusOnly
        managedObjectContext.perform {
            do {
                try managedObjectContext.execute(batchRequest)
            } catch {
                print(error)
            }
        }
    }
}
