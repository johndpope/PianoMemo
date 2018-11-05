//
//  LocalStorageService.swift
//  Piano
//
//  Created by hoemoon on 26/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

/// 로컬 저장소 상태를 변화시키는 모든 인터페이스 제공

typealias LocalStorageProvider = EmojiProvider & FetchedResultsProvider

protocol EmojiProvider: class {
    var emojiTags: [String] { get set }
}

protocol FetchedResultsProvider: class {
    var syncController: Synchronizable! { get set }
    var masterResultsController: NSFetchedResultsController<Note> { get }
    var trashResultsController: NSFetchedResultsController<Note> { get }

    var mainContext: NSManagedObjectContext { get }
    var privateQueue: OperationQueue { get }
    var backgroundContext: NSManagedObjectContext { get }

    func setup()
    func processDelayedTasks()
    func mergeables(originNote: Note) -> [Note]
    func search(keyword: String, tags: String, completion: @escaping ([Note]) -> Void)

    func refreshNoteListFetchLimit(with count: Int)
    func refreshTrashListFetchLimit(with count: Int)
}

class LocalStorageService: NSObject, FetchedResultsProvider, EmojiProvider {
    // MARK: emoji manage delegate
    var emojiTags: [String] {
        get {
            if let value = keyValueStore.array(forKey: "emojiTags") as? [String] {
                return value
            } else {
                return ["❤️"]
            }
        }
        set {
            keyValueStore.set(newValue, forKey: "emojiTags")
        }
    }
    var didDelayedTasks = false

    weak var syncController: Synchronizable!

    public lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Light")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    private let keyValueStore = NSUbiquitousKeyValueStore.default

    var mainContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    lazy var backgroundContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = mainContext
        context.name = "background context"
        return context
    }()

    private lazy var noteFetchRequest: NSFetchRequest<Note> = {
        let request:NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
        request.predicate = NSPredicate(format: "isRemoved == false")
        request.fetchLimit = 100
        request.sortDescriptors = [sort]
        return request
    }()

    private lazy var trashFetchRequest: NSFetchRequest<Note> = {
        let request:NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
        request.predicate = NSPredicate(format: "isRemoved == true")
        request.sortDescriptors = [sort]
        return request
    }()

    @objc lazy var searchQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    @objc lazy var privateQueue: OperationQueue = {
        let queue = OperationQueue()
        return queue
    }()

    lazy var masterResultsController: NSFetchedResultsController<Note> = {
        let controller = NSFetchedResultsController(
            fetchRequest: noteFetchRequest,
            managedObjectContext: backgroundContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        return controller
    }()

    lazy var trashResultsController: NSFetchedResultsController<Note> = {
        let controller = NSFetchedResultsController(
            fetchRequest: trashFetchRequest,
            managedObjectContext: backgroundContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        return controller
    }()

    func setup() {
        keyValueStore.synchronize()
        addObservers()
    }

    func processDelayedTasks() {
        if didDelayedTasks == false {
            deleteMemosIfPassOneMonth()
            addTutorialsIfNeeded()
            migrateEmojiTags()
            handlerNotUploaded()
            didDelayedTasks = true
        }
    }

    private func addObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(synchronizeKeyStore(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: nil
        )
        //        addObserver(self, forKeyPath: #keyPath(serialQueue.operationCount), options: [.old, .new], context: nil)
    }

    // for debug
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(privateQueue.operationCount) {
            print(privateQueue.operationCount)
        }
    }

    @objc func synchronizeKeyStore(_ notificaiton: Notification) {
        keyValueStore.synchronize()
        NotificationCenter.default.post(name: .refreshEmoji, object: nil)
    }

    func handlerNotUploaded() {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
        request.predicate = NSPredicate(format: "recordArchive = nil")
        request.sortDescriptors = [sort]

        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            do {
                let fetched = try self.backgroundContext.fetch(request)
                self.upload(notes: fetched)
            } catch {
                print(error)
            }
        }
    }

    func search(keyword: String, tags: String, completion: @escaping ([Note]) -> Void) {
        let search = SearchNoteOperation(
            controller: masterResultsController,
            context: backgroundContext,
            completion: completion)
        search.setRequest(keyword: keyword, tags: tags)
        searchQueue.cancelAllOperations()
        searchQueue.addOperation(search)
    }

    func refreshNoteListFetchLimit(with count: Int) {
        noteFetchRequest.fetchLimit += count
    }

    func refreshTrashListFetchLimit(with count: Int) {
        trashFetchRequest.fetchLimit += count
    }
    
    func mergeables(originNote: Note) -> [Note] {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
        request.predicate = NSPredicate(format: "isRemoved == false && isShared == false && SELF != %@", originNote)
        request.sortDescriptors = [sort]
        
        do {
            return try backgroundContext.fetch(request)
        } catch {
            print(error.localizedDescription)
        }
        return []
    }
}

extension LocalStorageService {
    private func deleteMemosIfPassOneMonth() {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.predicate = NSPredicate(format: "isRemoved == true AND modifiedAt < %@", NSDate(timeIntervalSinceNow: -3600 * 24 * 30))
        if let fetched = try? backgroundContext.fetch(request) {
            purge(notes: fetched) {}
        }
    }

    private func addTutorialsIfNeeded() {
        guard keyValueStore.bool(forKey: "didAddTutorials") == false else { return }
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.predicate = NSPredicate(value: true)
        request.sortDescriptors = []
        guard let fetched = try? backgroundContext.fetch(request),
            fetched.count < 0 else { return }

        create(string: "tutorial5".loc, tags: "") {}
        create(string: "tutorial4".loc, tags: "") {}
        create(string: "tutorial1".loc, tags: "") {}
        create(string: "tutorial2".loc, tags: "") {}
        create(string: "tutorial3".loc, tags: "") { [weak self] in
            guard let self = self else { return }
            self.keyValueStore.set(true, forKey: "didAddTutorials")
        }
    }

    private func migrateEmojiTags() {
        if let oldEmojis = UserDefaults.standard.value(forKey: "tags") as? [String] {
            let filtered = oldEmojis.filter { !emojiTags.contains($0) }
            var currentEmojis = emojiTags
            currentEmojis.append(contentsOf: filtered)
            emojiTags = currentEmojis
            UserDefaults.standard.removeObject(forKey: "tags")
        }
    }
}
