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
    var backgroundContext: NSManagedObjectContext { get }
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
            do {
                try self.viewContext.setQueryGenerationFrom(token)
            } catch {
                print(error)
            }
        }
        backgroundContext.perform {
            do {
                try self.backgroundContext.setQueryGenerationFrom(token)
            } catch {
                print(error)
            }
        }
    }

    fileprivate func setupContextNotificationObserving() {
        addObserverToken(
            backgroundContext.addContextDidSaveNotificationObserver { noti in
                self.syncContextDidSave(noti)
            }
        )

        addObserverToken(
            viewContext.addContextDidSaveNotificationObserver { noti in
                self.viewContextDidSave(noti)
            }
        )
    }

    fileprivate func syncContextDidSave(_ noti: ContextDidSaveNotification) {
        viewContext.performMergeChanges(from: noti)
//        notifyAboutChangedObjects(from: noti)
    }

    fileprivate func viewContextDidSave(_ noti: ContextDidSaveNotification) {
        backgroundContext.performMergeChanges(from: noti)
        notifyAboutChangedObjects(from: noti)
    }

    fileprivate func notifyAboutChangedObjects(from notification: ContextDidSaveNotification) {
        backgroundContext.perform(group: syncGroup) { [weak self] in
            guard let self = self else { return }
            let updates = notification.updatedObjects.remap(to: self.backgroundContext)
            let inserts = notification.insertedObjects.remap(to: self.backgroundContext)
            self.processChangedLocalObjects(updates + inserts)
        }
    }
}
