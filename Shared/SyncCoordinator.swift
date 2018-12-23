//
//  SyncCoordinator.swift
//  Piano
//
//  Created by hoemoon on 20/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

protocol ObserverTokenStore: class {
    func addObserverToken(_ token: NSObjectProtocol)
}

/// SyncCoordinator helper protocol
/// It receives application active / background state changes
/// and forwards them after switching onto the right queue.
protocol ApplicationActiveStateObserving: ObserverTokenStore {
    /// runs the given block on the right queue and dispatch group.
    func perform(_ block: @escaping () -> Void)
    /// Called when the application becomes active
    func applicationDidBecomeActive()
    func applicationDidEnterBackground()
}

extension ApplicationActiveStateObserving {
    private var center: NotificationCenter {
        return NotificationCenter.default
    }
    func setupApplicationActiveNotifications() {
        let didEnterBackground = center.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil, queue: nil) { [weak self] _ in
                guard let observer = self else { return }
                observer.perform {
                    observer.applicationDidEnterBackground()
                }
        }

        let didBecomeActive = center.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil, queue: nil) { [weak self] _ in
                guard let observer = self else { return }
                observer.perform {
                    observer.applicationDidEnterBackground()
                }
        }
        addObserverToken(didEnterBackground)
        addObserverToken(didBecomeActive)
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState == .active {
                self.applicationDidBecomeActive()
            }
        }
    }
}

/// Implements the integration with core data change notification
/// This protocol merge changes the view context into the sync context and vice versa.
/// It calls its `process(changedLocalObjects:)` methods when objects have changed.
protocol ContextOwner: ObserverTokenStore {
    var viewContext: NSManagedObjectContext { get }
    /// The managed object context that is used to perform synchronization with eh backend
    var syncContext: NSManagedObjectContext { get }
    /// This group tracks any outstanding work.
    var syncGroup: DispatchGroup { get }

    /// Will be called whenever objects on the sync managed object context have changed.
    func processChangedLocalObjects(_ objects: [NSManagedObject])
}

extension ContextOwner {
    func setupContexts() {
        setupQueryGenerations()
        setupContextNotificationObserving()
    }

    fileprivate func setupQueryGenerations() {
        let token = NSQueryGenerationToken.current
        viewContext.perform {
            try! self.viewContext.setQueryGenerationFrom(token)
        }
        syncContext.perform {
            try! self.syncContext.setQueryGenerationFrom(token)
        }
    }

    fileprivate func setupContextNotificationObserving() {
        addObserverToken(
            viewContext.addContextDidSaveNotificationObserver { noti in
                self.viewContextDidSave(noti)
            }
        )
        addObserverToken(
            syncContext.addContextDidSaveNotificationObserver { noti in
                self.syncContextDidSave(noti)
            }
        )
    }

    fileprivate func viewContextDidSave(_ noti: ContextDidSaveNotification) {
        syncContext.performMergeChanges(from: noti)
        notifyAboutChangedObjects(from: noti)
    }

    fileprivate func syncContextDidSave(_ noti: ContextDidSaveNotification) {
        viewContext.performMergeChanges(from: noti)
        notifyAboutChangedObjects(from: noti)
    }

    fileprivate func notifyAboutChangedObjects(from notification: ContextDidSaveNotification) {
        syncContext.perform(group: syncGroup) {
            let updates = notification.updatedObjects.remap(to: self.syncContext)
            let inserts = notification.insertedObjects.remap(to: self.syncContext)
            self.processChangedLocalObjects(updates + inserts)
        }
    }
}


final class SyncCoordinator {
    let viewContext: NSManagedObjectContext
    let syncContext: NSManagedObjectContext
    let syncGroup = DispatchGroup()

    let remote: RemoteProvider

    fileprivate var observerTokens = [NSObjectProtocol]()
    let changeProcessors: [ChangeProcessor]

    // TODO:
//    var teardownFlag = atomic_flag()

    public init(container: NSPersistentContainer) {
        viewContext = container.viewContext
        syncContext = container.newBackgroundContext()
        remote = CloudService(context: syncContext)
        remote.setupSubscription()
        // TODO: merge polich
        changeProcessors = [RemoteUploader(), RemoteRemover()]
        setup()
    }

    /// The `tearDown` method must be called in order to stop the sync coordinator.
    public func tearDown() {
    }

    deinit {
        // we must not call teadDown() at this point, because we can not call async code from within deinit.
        // We want to be able to call asyn code inside tearDown() to make sure things run on the right thread.
    }

    fileprivate func setup() {
        perform {
            self.setupContexts()
            self.setupChangeProcessors()
            self.setupApplicationActiveNotifications()
        }
    }

    fileprivate func setupChangeProcessors() {
        for cp in self.changeProcessors {
            cp.setup(for: self)
        }
    }

}
// MARK: - Remote -

extension SyncCoordinator {
    fileprivate func fetchRemoteDataForApplicationDidBecomeActive() {

    }

    fileprivate func fetchLatestRemoteData() {
        perform {
            for changeProcessor in self.changeProcessors {
                changeProcessor.fetchLatestRemoteRecords(in: self)
                self.delayedSaveOrRollback()
            }
        }
    }

    fileprivate func fetchNewRemoteData() {

    }

    fileprivate func processRemoteChanges<T>(_ changes: [RemoteRecordChange<T>], completion: @escaping () -> Void) {
        self.changeProcessors.asyncForEach(completion: completion) {
            _, _ in

        }
    }
}

protocol RemoteRecord {

}
enum RemoteRecordChange<T: RemoteRecord> {
    case insert(T)
    case update(T)
    case delete(CKRecord.ID)
}

extension Sequence {
    func asyncForEach(completion: @escaping () -> Void, block: (Iterator.Element, @escaping () -> Void) -> Void) {
        let group = DispatchGroup()
        let innerCompletion = { group.leave() }
        for x in self {
            group.enter()
            block(x, innerCompletion)
        }
        group.notify(queue: DispatchQueue.main, execute: completion)
    }
}

protocol ChangeProcessorContext: class {
    var context: NSManagedObjectContext { get }
    var remote: RemoteProvider { get }
    func perform(_ block: @escaping () -> Void)
    func delayedSaveOrRollback()
}

extension SyncCoordinator: ChangeProcessorContext {
    var context: NSManagedObjectContext {
        return syncContext
    }

    func perform(_ block: @escaping () -> Void) {
        syncContext.perform(group: syncGroup, block: block)
    }

    func delayedSaveOrRollback() {
        context.delayedSaveOrRollback(group: syncGroup)
    }
}

final class EntityAndPredicate<A: NSManagedObject> {
    let entity: NSEntityDescription
    let predicate: NSPredicate

    init(entity: NSEntityDescription, predicate: NSPredicate) {
        self.entity = entity
        self.predicate = predicate
    }
}

extension EntityAndPredicate {
    var fetchRequest: NSFetchRequest<A> {
        let request = NSFetchRequest<A>()
        request.entity = entity
        request.predicate = predicate
        return request
    }
}

extension Sequence where Iterator.Element: NSManagedObject {
    func filter(_ entityAndPredicate: EntityAndPredicate<Iterator.Element>) -> [Iterator.Element] {
        typealias MO = Iterator.Element
        let filtered = filter { (mo: MO) -> Bool in
            guard mo.entity === entityAndPredicate.entity else { return false }
            return entityAndPredicate.predicate.evaluate(with: mo)
        }
        return Array(filtered)
    }
}

protocol ChangeProcessor {
    func setup(for context: ChangeProcessorContext)
    func processChangedLocalObjects(_ objects: [NSManagedObject], in context: ChangeProcessorContext)
    func entityAndPredicateForLocallyTrackedObjects(in context: ChangeProcessorContext) -> EntityAndPredicate<NSManagedObject>?
    func processRemoteChanges<T>(_ changes: [RemoteRecordChange<T>], in context: ChangeProcessorContext, completion: () -> Void)
    func fetchLatestRemoteRecords(in context: ChangeProcessorContext)
}


extension SyncCoordinator: ContextOwner {
    func addObserverToken(_ token: NSObjectProtocol) {
        observerTokens.append(token)
    }

    func removeAllObserverTokens() {
        observerTokens.removeAll()
    }

    func processChangedLocalObjects(_ objects: [NSManagedObject]) {
        for cp in changeProcessors {
            cp.processChangedLocalObjects(objects, in: self)
        }
    }
}

extension SyncCoordinator: ApplicationActiveStateObserving {
    func applicationDidBecomeActive() {

    }

    func applicationDidEnterBackground() {

    }

    fileprivate func fetchLocallyTrackedObjects() {
        self.perform {
            // TODO: Could optimize this to only execute a single fetch request per entity.
            var objects = Set<NSManagedObject>()
            for cp in self.changeProcessors {
                guard let entityAndPredicate = cp.entityAndPredicateForLocallyTrackedObjects(in: self)
                    else { continue }
                let request = entityAndPredicate.fetchRequest
                request.returnsObjectsAsFaults = false
                let result = try! self.syncContext.fetch(request)
                objects.formUnion(result)
            }
            self.processChangedLocalObjects(Array(objects))
        }
    }
}

protocol ElementChangeProcessor: ChangeProcessor {
    associatedtype Element: NSManagedObject, Managed

    var elementsInProgress: InProgressTracker<Element> { get }

    /// Any objects matching the predicate
    func processChangedLocalElements(_ elements: [Element], in context: ChangeProcessorContext)

    var predicateForLocallyTrackedElements: NSPredicate { get }
}

extension ElementChangeProcessor {
    // Filters the `NSManagedObjects` according to the `entityAndPredicateForLocallyTrackedObjects(in:)` and forwards the results to `processChangedLocalElements(_:context:completion:)`
    func processChangedLocalObjects(_ objects: [NSManagedObject], in context: ChangeProcessorContext) {
        let matching = objects.filter(entityAndPredicateForLocallyTrackedObjects(in: context)!)
        if let elements = matching as? [Element] {
            let newElements = elementsInProgress.objectsToProgress(from: elements)
            processChangedLocalElements(newElements, in: context)
        }
    }

    func entityAndPredicateForLocallyTrackedObjects(in context: ChangeProcessorContext) -> EntityAndPredicate<NSManagedObject>? {
        let predicate = predicateForLocallyTrackedElements
        return EntityAndPredicate(entity: Element.entity(), predicate: predicate)
    }
}
