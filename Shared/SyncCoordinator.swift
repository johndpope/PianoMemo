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
import Reachability

protocol ObserverTokenStore: class {
    func addObserverToken(_ token: NSObjectProtocol)
}

final class SyncCoordinator {
    let viewContext: NSManagedObjectContext
    let backgroundContext: NSManagedObjectContext
    let syncGroup = DispatchGroup()

    let remote: RemoteProvider

    fileprivate var observerTokens = [NSObjectProtocol]()
    let changeProcessors: [ChangeProcessor]
    var didPerformDelayed = false

    lazy var privateQueue: OperationQueue = OperationQueue()
    private lazy var reachability = Reachability()

    // TODO:
//    var teardownFlag = atomic_flag()

    public init(container: NSPersistentContainer) {
        viewContext = container.viewContext
        backgroundContext = container.newBackgroundContext()
        // TODO: merge policy 개선
        backgroundContext.mergePolicy = NSMergePolicy.rollback
        viewContext.mergePolicy = NSMergePolicy.rollback
        remote = CloudService(context: backgroundContext)
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
            self.setupApplicationActiveNotifications()
            self.remote.setupSubscription()
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(performDelayed(_:)),
            name: .didFinishHandleZoneChange, object: nil
        )
    }

    @objc func performDelayed(_ notification: Notification) {
        guard !didPerformDelayed else { return }
        privateQueue.addOperation { [unowned self] in
            self.addTutorialsIfNeeded()
            self.didPerformDelayed = true
        }
    }

    func saveContexts() {
        backgroundContext.saveOrRollback()
    }

    func registerReachabilityNotification() {
        guard let reachability = reachability else { return }
        reachability.whenReachable = {
            [weak self] reachability in
            guard let self = self else { return }
            self.fetchLocallyTrackedObjects()
        }
        do {
            try reachability.startNotifier()
        } catch {
            print(error)
        }
    }
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
        return backgroundContext
    }

    func perform(_ block: @escaping () -> Void) {
        backgroundContext.perform(group: syncGroup, block: block)
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
//        syncContext.refreshAllObjects()
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
                do {
                    let result = try self.backgroundContext.fetch(request)
                    objects.formUnion(result)
                } catch {
                    print(error)
                }
            }
            self.processChangedLocalObjects(Array(objects))
        }
    }
}

// MARK: - Remote -

extension SyncCoordinator {
    fileprivate func fetchRemoteDataForApplicationDidBecomeActive() {
        remote.fetchChanges(in: .private, needByPass: false, needRefreshToken: false) { _ in}
        remote.fetchChanges(in: .shared, needByPass: false, needRefreshToken: false) { _ in}
    }
}

extension SyncCoordinator {
    private func addTutorialsIfNeeded() {
        guard KeyValueStore.default.bool(forKey: "didAddTutorials") == false else { return }
        if Note.count(in: backgroundContext) == 0 {
            backgroundContext.createLocally(content: "5. How to add the schedules\n♩ Write down the time/details to add your schedules.\n✷ Ex: Meeting with Cocoa at 3 pm\n✷ When you write something after using shortcut keys and putting a spacing, you can also add it on reminder.\n✷ Ex: -To buy iPhone charger.".loc, tags: "")
            backgroundContext.createLocally(content: "4. How to use Emoji List\n♩ Use the shortcut keys (-,* etc), and put a space to make it list.\n✷ Both shortcut keys and emoji can be modified in the Customized List of the settings.".loc, tags: "")
            backgroundContext.createLocally(content: "3. How to highlight\n♩ Click the ‘Highlighter’ button below.\n✷ Slide the texts you want to highlight from left to right.\n✷ When you slide from right to left, the highlight will be gone.\n✷ Go to “How to use” in Setting to see further information.".loc, tags: "")
            backgroundContext.createLocally(content: "2. How to tag with Memo\n♩ On any memo, tap and hold the tag to paste it into the memo you want to tag with.\n✷ If you'd like to un-tag it, paste the same tag back into the memo.\n✷ Go to “How to use” in Setting to see further information.".loc, tags: "")
            backgroundContext.createLocally(content: "1. The quickest way to copy the text\n♩ slide texts to the left side to copy them\n✷ Tap Select on the upper right, and you can copy the text you like.\n✷ Click “Convert” on the bottom right to send the memo as Clipboard, image or PDF.\n✷ Go to “How to use” in Navigate to see further information.".loc, tags: "")
            KeyValueStore.default.set(true, forKey: "didAddTutorials")
        }
    }
}
