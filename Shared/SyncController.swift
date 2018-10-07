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
    var foregroundContext: NSManagedObjectContext { get }
    var trashResultsController: NSFetchedResultsController<Note> { get }

    func search(with keyword: String, completionHandler: @escaping ([Note]) -> Void)
    func increaseFetchLimit(count: Int)
    func createNote(with attributedString: NSAttributedString,
                completionHandler: ((_ note: Note) -> Void)?)

    func fetchChanges(in scope: CKDatabase.Scope, comletionHandler: @escaping () -> Void)

    func setMainUIRefreshDelegate(_ delegate: UIRefreshDelegate)
    func setTrashUIRefreshDelegate(_ delegate: UIRefreshDelegate, completion: @escaping () -> Void)
    func unsetTrashUIRefreshDelegate()
    func update(note: Note, with attributedText: NSAttributedString, completion: @escaping (Note) -> Void)
    func requestShare(
        record: CKRecord,
        title: String?,
        thumbnailImageData: Data?,
        preparationHandler: @escaping PreparationHandler)
    func acceptShare(metadata: CKShare.Metadata, completion: @escaping () -> Void)
    func purge(note: Note, completion: @escaping () -> Void)
    func purgeAll()
    func restoreAll()
    func increaseTrashFetchLimit(count: Int)
    func setup()
    func delete(note: Note)
    func unlockNote(_ note: Note, completion: @escaping () -> Void)
    func lockNote(_ note: Note, completion: @escaping () -> Void)
    func restore(note: Note, completion: @escaping () -> Void)
}

class SyncController: Synchronizable {
    private let localStorageService: LocalStorageServiceDelegate
    private let remoteStorageService: RemoteStorageServiceDelegate

    var foregroundContext: NSManagedObjectContext {
        return localStorageService.foregroundContext
    }

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

    func createNote(with attributedString: NSAttributedString, completionHandler: ((Note) -> Void)?) {
        localStorageService.create(with: attributedString, completionHandler: completionHandler)
    }

    func search(with keyword: String, completionHandler: @escaping ([Note]) -> Void) {
        localStorageService.fetch(with: keyword, completionHandler: completionHandler)
    }

    func setMainUIRefreshDelegate(_ delegate: UIRefreshDelegate) {
        localStorageService.mainRefreshDelegate = delegate
    }

    func setTrashUIRefreshDelegate(_ delegate: UIRefreshDelegate, completion: @escaping () -> Void) {
        localStorageService.trashRefreshDelegate = delegate
        localStorageService.refreshUI {
            completion()
        }
    }

    func unsetTrashUIRefreshDelegate() {
        localStorageService.trashRefreshDelegate = nil
    }

    func update(note: Note, with attributedText: NSAttributedString, completion: @escaping (Note) -> Void) {
        localStorageService.update(note: note, with: attributedText, completion: completion)
    }

    func requestShare(
        record: CKRecord,
        title: String?,
        thumbnailImageData: Data?,
        preparationHandler: @escaping PreparationHandler) {

        remoteStorageService.requestShare(
            record: record,
            title: title,
            thumbnailImageData: thumbnailImageData,
            preparationHandler: preparationHandler
        )
    }

    func acceptShare(metadata: CKShare.Metadata, completion: @escaping () -> Void) {
        remoteStorageService.acceptShare(metadata: metadata, completion: completion)
    }

    func purge(note: Note, completion: @escaping () -> Void) {
        localStorageService.purge(note: note, completion: completion)
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
    func restore(note: Note, completion: @escaping () -> Void) {
        localStorageService.restore(note: note, completion: completion)
    }

    func unlockNote(_ note: Note, completion: @escaping () -> Void) {
        localStorageService.unlockNote(note, completion: completion)
    }
    func lockNote(_ note: Note, completion: @escaping () -> Void) {
        localStorageService.lockNote(note, completion: completion)
    }
}
