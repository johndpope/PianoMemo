//
//  ContextOwner.swift
//  Piano
//
//  Created by hoemoon on 24/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData

protocol ContextOwner: ObserverTokenStore {
    var viewContext: NSManagedObjectContext { get }
    var syncContext: NSManagedObjectContext { get }
    var syncGroup: DispatchGroup { get }
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
            print((updates + inserts).count, "(updates + inserts).count")
            self.processChangedLocalObjects(updates + inserts)
        }
    }
}
