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

typealias SyncFlag = SyncCoordinator.Flag

/// 동기화에 연관되는 여러가지 객체들을 소유합니다.
final class SyncCoordinator {
    enum Flag: String {
        case markedForUploadReserved
        case markedForRemoteDeletion
        case markedForDeletionDate
    }

    let viewContext: NSManagedObjectContext
    let backgroundContext: NSManagedObjectContext
    let syncGroup = DispatchGroup()
    lazy var privateQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    var teardownFlag = atomic_flag()

    let remote: RemoteProvider

    var observerTokens = [NSObjectProtocol]()
    let changeProcessors: [ChangeProcessor]
    var didPerformDelayed = false

    private lazy var reachability = Reachability()

    public init(
        container: NSPersistentContainer,
        remoteProvider: RemoteProvider,
        changeProcessors: [ChangeProcessor]) {

        viewContext = container.viewContext
        backgroundContext = container.newBackgroundContext()
        // TODO: merge policy 개선
        backgroundContext.mergePolicy = NSMergePolicy.overwrite
        viewContext.mergePolicy = NSMergePolicy.overwrite
        viewContext.name = "View Context"
        backgroundContext.name = "Background Context"
        remote = remoteProvider
        self.changeProcessors = changeProcessors
        setup()
    }

    /// The `tearDown` method must be called in order to stop the sync coordinator.
    public func tearDown() {
        guard !atomic_flag_test_and_set(&teardownFlag) else { return }
        perform {
            self.removeAllObserverTokens()
        }
    }

    deinit {
        guard atomic_flag_test_and_set(&teardownFlag) else {
            fatalError("deinit called without tearDown() being called.")
        }
        // We must not call tearDown() at this point, because we can not call async code from within deinit.
        // We want to be able to call async code inside tearDown() to make sure things run on the right thread.
    }

    fileprivate func setup() {
        perform {
            self.setupContexts()
            self.setupApplicationActiveNotifications()
            self.remote.setup(context: self.backgroundContext)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(performDelayed(_:)),
            name: .didFinishHandleZoneChange, object: nil
        )
    }

    /// didFinishHandleZoneChange 노티가 발생하게 되면,
    /// 반드시 리모트 저장소로 로컬을 업데이트 한 후에 수행되어야 하는 작업을 진행합니다.
    @objc func performDelayed(_ notification: Notification) {
        guard !didPerformDelayed else { return }
        let localMigration = MigrateLocallyOperation(context: viewContext)
        let pushFolders = PushFoldersOperation(context: viewContext, remote: remote)
        let pushNotes = PushNotesOperation(context: viewContext)
        let addTutorial = AddTutorialOperation(context: viewContext)
        let removeExpiredNote = BlockOperation { [weak self] in
            guard let self = self else { return }
            self.moveExpiredNote()
        }
        let completion = BlockOperation { [unowned self] in
            self.didPerformDelayed = true
        }
        pushFolders.addDependency(localMigration)
        pushNotes.addDependency(pushFolders)
        addTutorial.addDependency(pushNotes)
        removeExpiredNote.addDependency(addTutorial)
        completion.addDependency(removeExpiredNote)
        privateQueue.addOperations(
            [localMigration, pushFolders, pushNotes, addTutorial, removeExpiredNote, completion],
            waitUntilFinished: false
        )
    }

    private func moveExpiredNote() {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        let predicate = NSPredicate(format: "expireDate < %@ AND isRemoved == false", NSDate())
        request.predicate = predicate
        viewContext.performAndWait {
            do {
                let notes = try viewContext.fetch(request)
                notes.forEach {
                    $0.expireDate = nil
                    $0.isRemoved = true
                    $0.markUploadReserved()
                }
                context.saveOrRollback()
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func saveContexts() {
        backgroundContext.saveOrRollback()
        viewContext.saveOrRollback()
    }

    /// Reachability를 등록합니다.
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

extension SyncCoordinator {
    /// 각 changeProcessor를 순회하면서 fetchRequest를 생성해서 fetch 합니다.
    func fetchLocallyTrackedObjects() {
        backgroundContext.performAndWait {
            var objects = Set<NSManagedObject>()
            for cp in changeProcessors {
                guard let entityAndPredicate = cp.entityAndPredicateForLocallyTrackedObjects(in: self)
                    else { continue }
                let request = entityAndPredicate.fetchRequest
                request.returnsObjectsAsFaults = false
                do {
                    let result = try backgroundContext.fetch(request)
                    objects.formUnion(result)
                } catch {
                    print(error)
                }
            }
            self.processChangedLocalObjects(Array(objects))
        }
    }

    func fetchRemoteDataForApplicationDidBecomeActive() {
        remote.fetchChanges(in: .private, needByPass: false, needRefreshToken: false) { _ in}
//        remote.fetchChanges(in: .shared, needByPass: false, needRefreshToken: false) { _ in}
    }
}
