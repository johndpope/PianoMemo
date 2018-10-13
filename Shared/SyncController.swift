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
    var mainResultsController: NSFetchedResultsController<Note> { get }
    var trashResultsController: NSFetchedResultsController<Note> { get }
    var mergeables: [Note]? { get }

    func search(keyword: String, tags: String, completion: @escaping () -> Void)

    func create(string: String, tags: String, completion: @escaping () -> Void)
    func create(
        attributedString: NSAttributedString,
        tags: String,
        completion: @escaping () -> Void
    )
    func update(note origin: Note,
                with attributedString: NSAttributedString,
                completion: @escaping () -> Void
    )
    func move(note: Note, to tags: String, completion: @escaping () -> Void)
    func remove(note: Note, completion: @escaping () -> Void)
    func restore(note: Note, completion: @escaping () -> Void)
    func purge(notes: [Note], completion: @escaping () -> Void)
    func purgeAll(completion: @escaping () -> Void)
    func merge(origin: Note, deletes: [Note], completion: @escaping () -> Void)
    func lockNote(_ note: Note, completion: @escaping () -> Void)
    func unlockNote(_ note: Note, completion: @escaping () -> Void)

    func increaseFetchLimit(count: Int)
    func increaseTrashFetchLimit(count: Int)
    func setup()

    func fetchChanges(in scope: CKDatabase.Scope, comletionHandler: @escaping () -> Void)

    // MARK: share
    func requestShare(
        recordToShare: CKRecord,
        preparationHandler: @escaping PreparationHandler)
    func requestManageShare(
        shareRecordID: CKRecord.ID,
        preparationHandler: @escaping PreparationHandler)
    func acceptShare(metadata: CKShare.Metadata, completion: @escaping () -> Void)

    func saveContext()
    func setByPass()
    func setShareAcceptable(_ delegate: ShareAcceptable)
}

class SyncController: Synchronizable {
    func search(keyword: String, tags: String, completion: @escaping () -> Void) {
        localStorageService.search(keyword: keyword, tags: tags, completion: completion)
    }

    func create(string: String, tags: String, completion: @escaping () -> Void) {
        localStorageService.create(string: string, tags: tags, completion: completion)
    }

    func create(attributedString: NSAttributedString, tags: String, completion: @escaping () -> Void) {
        localStorageService.create(attributedString: attributedString, tags: tags, completion: completion)
    }

    func update(note origin: Note,
                with attributedString: NSAttributedString,
                completion: @escaping () -> Void) {
        localStorageService.update(
            note: origin,
            attributedString: attributedString,
            string: nil,
            isRemoved: nil,
            isLocked: nil,
            changedTags: nil,
            needUpdateDate: true,
            completion: completion
        )
    }

    func move(note: Note, to tags: String, completion: @escaping () -> Void) {
        localStorageService.move(note: note, to: tags, completion: completion)
    }

    func remove(note: Note, completion: @escaping () -> Void) {
        localStorageService.remove(note: note, completion: completion)
    }

    func restore(note: Note, completion: @escaping () -> Void) {
        localStorageService.remove(note: note, completion: completion)
    }

    func purge(notes: [Note], completion: @escaping () -> Void) {
        localStorageService.purge(notes: notes, completion: completion)
    }

    func purgeAll(completion: @escaping () -> Void) {
        localStorageService.purgeAll(completion: completion)
    }

    func merge(origin: Note, deletes: [Note], completion: @escaping () -> Void) {
        localStorageService.merge(origin: origin, deletes: deletes, completion: completion)
    }

    func lockNote(_ note: Note, completion: @escaping () -> Void) {
        localStorageService.lockNote(note, completion: completion)
    }

    func unlockNote(_ note: Note, completion: @escaping () -> Void) {
        localStorageService.unlockNote(note, completion: completion)
    }

    private let localStorageService: LocalStorageServiceDelegate
    private let remoteStorageService: RemoteStorageServiceDelegate

    var mainResultsController: NSFetchedResultsController<Note> {
        return localStorageService.mainResultsController
    }

    var trashResultsController: NSFetchedResultsController<Note> {
        return localStorageService.trashResultsController
    }

    var mergeables: [Note]? {
        return localStorageService.mergeables
    }

    init(localStorageService: LocalStorageService = LocalStorageService(),
         remoteStorageService: RemoteStorageSerevice = RemoteStorageSerevice()) {

        self.localStorageService = localStorageService
        self.remoteStorageService = remoteStorageService

        localStorageService.remoteStorageServiceDelegate = remoteStorageService
        remoteStorageService.localStorageServiceDelegate = localStorageService
    }

    func setup() {
        remoteStorageService.setup()
        localStorageService.setup()
    }

    func fetchChanges(in scope: CKDatabase.Scope, comletionHandler: @escaping () -> Void) {
        remoteStorageService.fetchChanges(in: scope, completion: comletionHandler)
    }

    func increaseFetchLimit(count: Int) {
        localStorageService.increaseFetchLimit(count: count)
    }
    

    func requestShare(
        recordToShare: CKRecord,
        preparationHandler: @escaping PreparationHandler) {

        remoteStorageService.requestShare(
            recordToShare: recordToShare,
            preparationHandler: preparationHandler
        )
    }
    func requestManageShare(
        shareRecordID: CKRecord.ID,
        preparationHandler: @escaping PreparationHandler) {

        remoteStorageService.requestManageShare(
            shareRecordID: shareRecordID,
            preparationHandler: preparationHandler
        )
    }

    func acceptShare(metadata: CKShare.Metadata, completion: @escaping () -> Void) {
        remoteStorageService.acceptShare(metadata: metadata, completion: completion)
    }


    func increaseTrashFetchLimit(count: Int) {
        localStorageService.increaseTrashFetchLimit(count: count)
    }

    func saveContext() {
        localStorageService.saveContext()
    }
    func setByPass() {
        localStorageService.needBypass = true
    }
    func setShareAcceptable(_ delegate: ShareAcceptable) {
        localStorageService.shareAcceptable = delegate
    }
}
