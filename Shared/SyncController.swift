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

    func create(string: String, tags: String)
    func create(attributedString: NSAttributedString, tags: String)
    func update(note origin: Note,
                with attributedText: NSAttributedString)
    func delete(note: Note)
    func restore(note: Note)
    func purge(note: Note)
    func purgeAll()
    func restoreAll()

    func unlockNote(_ note: Note)
    func lockNote(_ note: Note)

    func increaseFetchLimit(count: Int)
    func increaseTrashFetchLimit(count: Int)
    func setup()

    func fetchChanges(in scope: CKDatabase.Scope, comletionHandler: @escaping () -> Void)


    func merge(origin: Note, deletes: [Note])
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
    
    func create(string: String, tags: String) {
        localStorageService.create(string: string, tags: tags)
    }

    
    func create(attributedString: NSAttributedString, tags: String) {
        localStorageService.create(attributedString: attributedString, tags: tags)
    }
    
    func search(keyword: String, tags: String, completion: @escaping () -> Void) {
        localStorageService.search(keyword: keyword, tags: tags, completion: completion)
    }

    func update(note origin: Note, with attributedText: NSAttributedString) {
        localStorageService.update(note: origin, with: attributedText, moveTrash: nil)
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

    func purge(note: Note) {
        localStorageService.purge(note: note)
    }

    func purgeAll() {
        localStorageService.purgeAll()
    }

    func restoreAll() {
        localStorageService.restoreAll()
    }

    func increaseTrashFetchLimit(count: Int) {
        localStorageService.increaseTrashFetchLimit(count: count)
    }
    func delete(note: Note) {
        localStorageService.remove(note: note)
    }
    func restore(note: Note) {
        localStorageService.restore(note: note)
    }

    func unlockNote(_ note: Note) {
        localStorageService.unlockNote(note)
    }
    func lockNote(_ note: Note) {
        localStorageService.lockNote(note)
    }

    func merge(origin: Note, deletes: [Note]) {
        localStorageService.merge(origin: origin, deletes: deletes)
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
