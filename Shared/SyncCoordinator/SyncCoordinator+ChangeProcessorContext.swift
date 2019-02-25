//
//  ChangeProcessorContext.swift
//  Piano
//
//  Created by hoemoon on 25/02/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import CoreData

/// changeProcessor가 사용하는 자원을 정의하는 프로토콜
protocol ChangeProcessorContext: class {
    var context: NSManagedObjectContext { get }
    var remote: RemoteProvider { get }
    func perform(_ block: @escaping () -> Void)
    func delayedSaveOrRollback()
}

extension SyncCoordinator: ChangeProcessorContext {
    var context: NSManagedObjectContext {
        return backgroundContext
    }

    func perform(_ block: @escaping () -> Void) {
        backgroundContext.perform(group: syncGroup, block: block)
    }

    func delayedSaveOrRollback() {
        context.saveOrRollback()
    }
}
