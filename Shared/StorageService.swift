//
//  SynchronizeController.swift
//  Piano
//
//  Created by hoemoon on 26/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

/// 실제로 프로그래머가 호출하는 모든 데이터 조작 인터페이스를 제공
protocol Synchronizable: class {
    var container: CKContainer { get }
    var privateDB: CKDatabase { get }
    var sharedDB: CKDatabase { get }

    var mainContext: NSManagedObjectContext { get }
    var backgroundContext: NSManagedObjectContext { get }

    func processDelayedTasks()
}

class StorageService {
    let local: LocalStorageService
    let remote: RemoteStorageSerevice

    init(local: LocalStorageService = LocalStorageService(),
         remote: RemoteStorageSerevice = RemoteStorageSerevice()) {
        self.local = local
        self.remote = remote
    }

    func setup() {
        local.syncController = self
        remote.syncController = self
        remote.setup()
        local.setup()
    }
}

extension StorageService: Synchronizable {
    var container: CKContainer {
        return remote.container
    }
    var privateDB: CKDatabase {
        return remote.privateDatabase
    }
    var sharedDB: CKDatabase {
        return remote.sharedDatabase
    }

    var mainContext: NSManagedObjectContext {
        return local.mainContext
    }

    var backgroundContext: NSManagedObjectContext {
        return local.backgroundContext
    }

    func processDelayedTasks() {
        local.processDelayedTasks()
    }
}
