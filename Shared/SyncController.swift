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
    var resultsController: NSFetchedResultsController<Note> { get }
    var trashResultsController: NSFetchedResultsController<Note> { get }

    func search(with keyword: String, completion: @escaping ([Note]) -> Void)

    func create(with attributedString: NSAttributedString)
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

    func mergeableNotes(with origin: Note) -> [Note]?
    func merge(origin: Note, deletes: [Note], completion: @escaping () -> Void)
    // MARK: share
    func requestShare(
        recordToShare: CKRecord,
        preparationHandler: @escaping PreparationHandler)
    func requestManageShare(
        shareRecordID: CKRecord.ID,
        preparationHandler: @escaping PreparationHandler)
    func acceptShare(metadata: CKShare.Metadata, completion: @escaping () -> Void)
    func saveContext()
}

class SyncController: Synchronizable {
    private let localStorageService: LocalStorageServiceDelegate
    private let remoteStorageService: RemoteStorageServiceDelegate

    var resultsController: NSFetchedResultsController<Note> {
        return localStorageService.mainResultsController
    }

    var trashResultsController: NSFetchedResultsController<Note> {
        return localStorageService.trashResultsController
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

    func create(with attributedString: NSAttributedString) {
        localStorageService.create(with: attributedString)
    }

    func search(with keyword: String, completion: @escaping ([Note]) -> Void) {
        localStorageService.search(with: keyword, completion: completion)
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
        localStorageService.delete(note: note)
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

    func mergeableNotes(with origin: Note) -> [Note]? {
        return localStorageService.mergeableNotes(with: origin)
    }

    func merge(origin: Note, deletes: [Note], completion: @escaping () -> Void) {
        localStorageService.merge(origin: origin, deletes: deletes, completion: completion)
    }

    func saveContext() {
        localStorageService.saveContext()
    }
}
