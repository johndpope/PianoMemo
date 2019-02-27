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

    deinit {
        guard atomic_flag_test_and_set(&teardownFlag) else {
            fatalError("deinit called without tearDown() being called.")
        }
        // We must not call tearDown() at this point, because we can not call async code from within deinit.
        // We want to be able to call async code inside tearDown() to make sure things run on the right thread.
    }
}

extension SyncCoordinator {
    private func setup() {
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

    /// The `tearDown` method must be called in order to stop the sync coordinator.
    func tearDown() {
        guard !atomic_flag_test_and_set(&teardownFlag) else { return }
        perform {
            self.removeAllObserverTokens()
        }
    }

    /// didFinishHandleZoneChange 노티가 발생하게 되면,
    /// 반드시 리모트 저장소로 로컬을 업데이트 한 후에 수행되어야 하는 작업을 진행합니다.
    @objc private func performDelayed(_ notification: Notification) {
        guard !didPerformDelayed else { return }
        // MigrateLocallyOperation에서 로컬에 있는 객체를 변경시키게 됩니다.
        // 결과로 폴더가 새로 생기고, 노트는 새로운 관계를 갖게 됩니다.
        // 이 새로운 관계를 원격 저장소에도 반영하기 위해서는
        // 원격 저장소에 폴더가 업로드 되어야 하고,
        // 로컬의 폴더 객체가 원격 저장소에서 생성한 메타 데이터를 가지고 있어야 합니다.
        // 그래서 폴더를 업로드 및 메타데이터를 갱신한 후,
        // 노트를 업로드하게 되면, 로컬의 관계가 원격 저장소에도 반영됩니다.
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

    /// changeProcessor들을 순회하면서 각 객체가 추적하는 코어데이터 객체들 대한
    /// fetchRequest를 생성해서 한후 백그라운드 컨텍스트에서 fetch 합니다.
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

    /// app이 active 상태가 되었을 때, 해야할 행동을 정의합니다.
    func fetchRemoteDataForApplicationDidBecomeActive() {
        remote.fetchChanges(in: .private, needByPass: false, needRefreshToken: false) { _ in}
//        remote.fetchChanges(in: .shared, needByPass: false, needRefreshToken: false) { _ in}
    }

    /// Reachability observer를 등록합니다.
    /// 네트워크 상태가 복구되면, 원격 저장소에 반영하지 못한 변경사항을 업로드하게 됩니다.
    private func registerReachabilityNotification() {
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
}
