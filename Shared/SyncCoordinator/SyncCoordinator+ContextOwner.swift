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

extension SyncCoordinator: ContextOwner {
    /// `fetchLocallyTrackedObjects()`
    /// 또는 `notifyAboutChangedObjects(from:)`에서
    /// 전달된 객체를 각 changeProcessor에 전달합니다.
    func processChangedLocalObjects(_ objects: [NSManagedObject]) {
        for cp in changeProcessors {
            cp.processChangedLocalObjects(objects, in: self)
        }
    }
}

extension ContextOwner {
    func setupContexts() {
        setupQueryGenerations()
        setupContextNotificationObserving()
    }

    /// 각 컨텍스트의 QueryGenerationToken을 현재의 것으로 고정시킵니다.
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

    /// 각각 컨텍스트 저장 노티에 대한 구독을 등록합니다.
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

    /// 백그라운드 컨텍스트 저장시 호출됩니다.
    /// 노티 결과를 뷰컨텍스트에 머지합니다.
    /// 변경 사항으로 changeProcessor를 동작시킵니다.
    fileprivate func syncContextDidSave(_ noti: ContextDidSaveNotification) {
        #if DEBUG
        print(#function, "😎")
        #endif
        viewContext.performMergeChanges(from: noti)
        notifyAboutChangedObjects(from: noti)
    }

    /// 뷰컨텍스트 저장시 호출됩니다.
    /// 노티 결과를 백그라운드 컨텍스트에 머지합니다.
    /// 변경 사항으로 changeProcessor를 동작시킵니다.
    fileprivate func viewContextDidSave(_ noti: ContextDidSaveNotification) {
        #if DEBUG
        print(#function, "🤩")
        #endif
        backgroundContext.performMergeChanges(from: noti)
        notifyAboutChangedObjects(from: noti)
        saveNotesToSharedGroup()
    }

    func saveNotesToSharedGroup() {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        let descriptor = NSSortDescriptor(key: "modifiedAt", ascending: false)
        let predicater = NSPredicate(format: "isRemoved == false AND isLocked == false")
        request.sortDescriptors = [descriptor]
        request.predicate = predicater
        request.fetchLimit = 2
        backgroundContext.perform {
            guard let results = try? self.backgroundContext.fetch(request) else {return}

            var notes: [[String: Any]] = []
            for note in results {
                let objectID = note.objectID.uriRepresentation().absoluteString
                let noteInfo = [
                    "id": objectID,
                    "title": note.title,
                    "subTitle": note.subTitle
                ]
                notes.append(noteInfo)
            }
            let defaults = UserDefaults(suiteName: "group.piano.container")
            defaults?.set(notes, forKey: "recentNotes")
        }
    }

    /// 발생한 노티에 포함된 정보를 이용해 코어데이터 객체로 바꿉니다.
    fileprivate func notifyAboutChangedObjects(from notification: ContextDidSaveNotification) {
        backgroundContext.perform(group: syncGroup) { [weak self] in
            guard let self = self else { return }
            let updates = notification.updatedObjects.remap(to: self.backgroundContext)
            let inserts = notification.insertedObjects.remap(to: self.backgroundContext)
            self.processChangedLocalObjects(updates + inserts)
        }
    }
}
