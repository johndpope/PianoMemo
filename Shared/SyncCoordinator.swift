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
        fetchLocallyTrackedObjects()
        fetchRemoteDataForApplicationDidBecomeActive()
    }

    func applicationDidEnterBackground() {
        syncContext.refreshAllObjects()
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
