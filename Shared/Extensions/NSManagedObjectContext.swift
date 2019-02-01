//
//  NSManagedObjectContext.swift
//  Piano
//
//  Created by hoemoon on 05/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CloudKit
import CoreData

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
        guard hasChanges else { return false }
        do {
            try save()
            return true
        } catch {
            rollback()
            return false
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

    func createLocally(content: String, tags: String) {
        perform { [weak self] in
            guard let self = self else { return }
            let note = Note.insert(into: self)
            note.content = content
            note.tags = tags
            self.saveOrRollback()
        }
    }
}

extension NSManagedObjectContext {
    // 확실히 이건 굉장히 비효율적임. 개선해야 함.
    // 앱 시작하면 메모리에 테이블 하나 만들어 놓고,
    // 변할 때마다 걔를 업데이트 해야 함
    func emojiSorter(first: String, second: String) -> Bool {
        do {
            let firstCount = try self.count(for: fetchRequest(with: first))
            let secondCount = try self.count(for: fetchRequest(with: second))
            return firstCount > secondCount
        } catch {
            return false
        }
    }

    private func fetchRequest(with emoji: String) -> NSFetchRequest<Note> {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
        let notRemovedPredicate = NSPredicate(format: "isRemoved == false")
        let emojiPredicate = NSPredicate(format: "tags contains[cd] %@", emoji)
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [notRemovedPredicate, emojiPredicate])
        request.sortDescriptors = [sort]
        return request
    }
}

// TODO:
//private let UserIDKey = "io.objc.Moody.CloudKitUserID"
//
//extension NSManagedObjectContext {
//    public var userID: RemoteRecordID? {
//        get {
//            return metaData[UserIDKey] as? RemoteRecordID
//        }
//        set {
//            guard newValue != userID else { return }
//            setMetaData(object: newValue.map { $0 as NSString }, forKey: UserIDKey)
//        }
//    }
//}
