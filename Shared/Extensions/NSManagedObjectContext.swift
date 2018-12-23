//
//  NSManagedObjectContext.swift
//  Piano
//
//  Created by hoemoon on 05/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CloudKit
import CoreData

extension NSManagedObjectContext {

    internal func saveIfNeeded() {
        self.performAndWait { [weak self] in
            guard let self = self,
                self.hasChanges else { return }
            do {
                try self.save()
            } catch {
                print("컨텍스트 저장하다 에러: \(error)")
            }
        }
    }

    func note(with recordID: CKRecord.ID) -> Note? {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
        request.predicate = NSPredicate(format: "%K == %@", "recordID", recordID as CVarArg)
        request.fetchLimit = 1
        request.sortDescriptors = [sort]

        do {
            let fetched = try fetch(request)
            return fetched.first
        } catch {
            return nil
        }
    }
}

struct ContextDidSaveNotification {
    init(noti: Notification) {
        guard noti.name == .NSManagedObjectContextDidSave else { fatalError() }
        notification = noti
    }

    var insertedObjects: AnyIterator<NSManagedObject> {
        return iterator(forKey: NSInsertedObjectsKey)
    }

    var updatedObjects: AnyIterator<NSManagedObject> {
        return iterator(forKey: NSUpdatedObjectsKey)
    }

    var deletedObjects: AnyIterator<NSManagedObject> {
        return iterator(forKey: NSDeletedObjectsKey)
    }

    var managedObjectContext: NSManagedObjectContext {
        guard let c = notification.object as? NSManagedObjectContext else {
            fatalError("Invalid notification object")
        }
        return c
    }

    fileprivate let notification: Notification
    fileprivate func iterator(forKey key: String) -> AnyIterator<NSManagedObject> {
        guard let set = (notification as Notification).userInfo?[key] as? NSSet else {
            return AnyIterator { nil }
        }
        var innerIterator = set.makeIterator()
        return AnyIterator { return innerIterator.next() as? NSManagedObject }
    }
}

struct ContextWillSaveNotification {
    init(noti: Notification) {
        guard noti.name == .NSManagedObjectContextWillSave else { fatalError() }
        notification = noti
    }

    var managedObjectContext: NSManagedObjectContext {
        guard let c = notification.object as? NSManagedObjectContext else {
            fatalError()
        }
        return c
    }

    fileprivate let notification: Notification
}

extension NSManagedObjectContext {
    func addContextDidSaveNotificationObserver(
        _ handler: @escaping (ContextDidSaveNotification) -> Void) -> NSObjectProtocol {

        return NotificationCenter.default
            .addObserver(forName: .NSManagedObjectContextDidSave, object: self, queue: nil) { noti in
                let wrappedNoti = ContextDidSaveNotification(noti: noti)
                handler(wrappedNoti)
        }
    }

    func addContextWillSaveNotificationObserver(
        _ handler: @escaping (ContextWillSaveNotification) -> Void) -> NSObjectProtocol {
        return NotificationCenter.default
            .addObserver(forName: .NSManagedObjectContextWillSave, object: self, queue: nil) { noti in
                let wrappedNoti = ContextWillSaveNotification(noti: noti)
                handler(wrappedNoti)
        }
    }

    func performMergeChanges(from noti: ContextDidSaveNotification) {
        perform {
            self.mergeChanges(fromContextDidSave: noti.notification)
        }
    }
}

extension NSManagedObjectContext {
    func perform(group: DispatchGroup, block: @escaping () -> Void) {
        group.enter()
        perform {
            block()
            group.leave()
        }
    }


    func insertObject<A: NSManagedObject>() -> A where A: Managed {
        guard let obj = NSEntityDescription.insertNewObject(forEntityName: A.entityName, into: self) as? A
            else { fatalError("Wrong object type") }
        return obj
    }

    fileprivate var changedObjectsCount: Int {
        return insertedObjects.count + updatedObjects.count + deletedObjects.count
    }

    @discardableResult
    func saveOrRollback() -> Bool {
        do {
            try save()
            return true
        } catch {
            rollback()
            return false
        }
    }

    func performChanges(block: @escaping () -> Void) {
        perform {
            block()
            self.saveOrRollback()
        }
    }

    func performChanges(block: @escaping () -> Void, completion: ((Bool) -> Void)?) {
        perform {
            block()
            let success = self.saveOrRollback()

            DispatchQueue.main.async {
                completion?(success)
            }
        }
    }

    func delayedSaveOrRollback(group: DispatchGroup, completion: @escaping (Bool) -> Void = { _ in }) {
        let changeCountLimit = 100
        guard changeCountLimit >= changedObjectsCount else {
            return completion(saveOrRollback())
        }
        let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
        group.notify(queue: queue) {
            self.perform(group: group) {
                guard self.hasChanges else { return completion(true) }
                completion(self.saveOrRollback())
            }
        }
    }
}

extension NSManagedObjectContext {
    func update(
        origin: Note,
        string: String? = nil,
        isRemoved: Bool? = nil,
        isLocked: Bool? = nil,
        isPinned: Int? = nil,
        tags: String? = nil,
        needUpdateDate: Bool = true,
        isShared: Bool? = nil,
        completion: ((Bool) -> Void)? = nil) {

        performChanges(block: {
            if let isRemoved = isRemoved {
                origin.isRemoved = isRemoved
            }
            if let string = string {
                origin.content = string
            }
            //  if let isLocked = isLocked {
            //      note.isLocked = isLocked
            //  }
            if let isPinned = isPinned {
                origin.isPinned = Int64(isPinned)
            }
            if let tags = tags {
                origin.tags = tags
            }
            if let isShared = isShared {
                origin.isShared = isShared
            }
            if needUpdateDate {
                origin.modifiedAt = Date() as NSDate
            }
            origin.markUploadReserved()
        }, completion: completion)
    }
}
