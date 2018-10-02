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
    var publicBackgroundContext: NSManagedObjectContext { get }

    func search(with keyword: String, completionHandler: @escaping ([Note]) -> Void)
    func setFetchResultsControllerDelegate(with delegate: NSFetchedResultsControllerDelegate)
    func increaseFetchLimit(count: Int)
    func createNote(with attributedString: NSAttributedString,
                completionHandler: ((_ note: Note) -> Void)?)

    func fetchChanges(in scope: CKDatabase.Scope, comletionHandler: @escaping () -> Void)
}

class SyncController: Synchronizable {
    private let localStorageService: LocalStorageServiceDelegate
    private let remoteStorageService: RemoteStorageServiceDelegate

    private var persistentContainer: NSPersistentContainer {
        return localStorageService.persistentContainer
    }

    var publicBackgroundContext: NSManagedObjectContext {
        return localStorageService.publicBackgroundContext
    }

    var resultsController: NSFetchedResultsController<Note> {
        return localStorageService.resultsController
    }


    init(localStorageService: LocalStorageService = LocalStorageService(),
         remoteStorageService: RemoteStorageSerevice = RemoteStorageSerevice()) {

        self.localStorageService = localStorageService
        self.remoteStorageService = remoteStorageService

        localStorageService.remoteStorageServiceDelegate = remoteStorageService
        remoteStorageService.localStorageServiceDelegate = localStorageService
    }

    func setFetchResultsControllerDelegate(with delegate: NSFetchedResultsControllerDelegate) {
        self.resultsController.delegate = delegate
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

}
