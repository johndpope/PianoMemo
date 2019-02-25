//
//  ChangeProcessorContext.swift
//  Piano
//
//  Created by hoemoon on 25/02/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import CoreData

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
        // TODO: 미뤄서 저장하기 개선
        //        context.delayedSaveOrRollback(group: syncGroup)
    }
}
