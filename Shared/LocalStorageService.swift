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
import Reachability

/// 로컬 저장소 상태를 변화시키는 모든 인터페이스 제공

class LocalStorageService: NSObject {
    // MARK: emoji manage delegate
    var emojiTags: [String] {
        get {
            if let value = keyValueStore.array(forKey: "emojiTags") as? [String] {
                return value
//                return value.sorted(by: emojiSorter)
            } else {
                return ["❤️", "🔒"]
            }
        }
        set {
            keyValueStore.set(newValue, forKey: "emojiTags")
            NotificationCenter.default.post(
                name: NSNotification.Name.refreshTextAccessory,
                object: nil
            )
        }
    }
    var didDelayedTasks = false
    var didHandleNotUploaded = false

    weak var syncController: Synchronizable!

    private lazy var reachability = Reachability()

    public var persistentContainer: NSPersistentContainer = {
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
        let date = NSSortDescriptor(key: "modifiedAt", ascending: false)
        let pinned = NSSortDescriptor(key: "isPinned", ascending: false)
        request.predicate = NSPredicate(format: "isRemoved == false")
        request.fetchLimit = 100
        request.sortDescriptors = [pinned, date]
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

    lazy var serialQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    lazy var masterResultsController: NSFetchedResultsController<Note> = {
        let controller = NSFetchedResultsController(
            fetchRequest: noteFetchRequest,
            managedObjectContext: mainContext,
            sectionNameKeyPath: nil,
            cacheName: "Note"
        )
        return controller
    }()

    lazy var trashResultsController: NSFetchedResultsController<Note> = {
        let controller = NSFetchedResultsController(
            fetchRequest: trashFetchRequest,
            managedObjectContext: mainContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        return controller
    }()

    func setup() {
        addObservers()
        registerReachabilityNotification()
    }

    func processDelayedTasks() {
        if didDelayedTasks == false {
            deleteMemosIfPassOneMonth()
            addTutorialsIfNeeded()
            migrateEmojiTags()
            didDelayedTasks = true
        }
    }

    func registerReachabilityNotification() {
        guard let reachability = reachability else { return }
        reachability.whenReachable = {
            [weak self] reachability in
            self?.handlerNotUploaded()
        }
        reachability.whenUnreachable = {
            [weak self] reachability in
            self?.didHandleNotUploaded = false
        }
        do {
            try reachability.startNotifier()
        } catch {
            print(error)
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
        NotificationCenter.default.post(name: .refreshTextAccessory, object: nil)
    }

    func handlerNotUploaded() {
        guard didHandleNotUploaded == false else { return }
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
        request.predicate = NSPredicate(format: "recordArchive = nil")
        request.sortDescriptors = [sort]

        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            do {
                let fetched = try self.backgroundContext.fetch(request)
                if fetched.count > 0 {
                    self.upload(notes: fetched)
                }
            } catch {
                print(error)
            }
            self.didHandleNotUploaded = true
        }
    }

    func filter(with tags: String, completion: @escaping () -> Void) {
        let filter = FilterNoteOperation(
            controller: masterResultsController,
            completion: completion)
        filter.setTags(tags)
        OperationQueue.main.addOperation(filter)
    }

    func search(keyword: String, completion: @escaping ([Note]) -> Void) {
        let search = TextSearchOperation(context: backgroundContext, completion: completion)
        search.setKeyword(keyword)
        searchQueue.cancelAllOperations()
        searchQueue.addOperation(search)
    }

    func refreshNoteListFetchLimit(with count: Int) {
        noteFetchRequest.fetchLimit += count
    }

    func refreshTrashListFetchLimit(with count: Int) {
        trashFetchRequest.fetchLimit += count
    }
    
    func mergeables() -> [Note] {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
        request.predicate = NSPredicate(format: "isRemoved == false && isShared == false")
        request.sortDescriptors = [sort]
        
        do {
            return try backgroundContext.fetch(request)
        } catch {
            print(error.localizedDescription)
            return []
        }
    }
}

extension LocalStorageService {
    private func deleteMemosIfPassOneMonth() {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
        request.sortDescriptors = [sort]
        request.predicate = NSPredicate(format: "isRemoved == true AND modifiedAt < %@", NSDate(timeIntervalSinceNow: -3600 * 24 * 30))
        do {
            let fetced = try backgroundContext.fetch(request)
            purge(notes: fetced)
        } catch {
            print(error)
        }
    }

    private func addTutorialsIfNeeded() {
        guard keyValueStore.bool(forKey: "didAddTutorials") == false else { return }
        do {
            let count = try backgroundContext.count(for: LocalStorageService.allfetchRequest())
            if count == 0 {
                createLocally(string: "1. The quickest way to copy the text\n♩ slide texts to the left side to copy them\n✷ Tap Select on the upper right, and you can copy the text you like.\n✷ Click “Convert” on the bottom right to send the memo as Clipboard, image or PDF.\n✷ Go to “How to use” in Navigate to see further information.".loc, tags: "")
                createLocally(string: "2. How to tag with Memo\n♩ On any memo, tap and hold the tag to paste it into the memo you want to tag with.\n✷ If you'd like to un-tag it, paste the same tag back into the memo.\n✷ Go to “How to use” in Setting to see further information.".loc, tags: "")
                createLocally(string: "3. How to highlight\n♩ Click the ‘Highlighter’ button below.\n✷ Slide the texts you want to highlight from left to right.\n✷ When you slide from right to left, the highlight will be gone.\n✷ Go to “How to use” in Setting to see further information.".loc, tags: "")
                createLocally(string: "4. How to use Emoji List\n♩ Use the shortcut keys (-,* etc), and put a space to make it list.\n✷ Both shortcut keys and emoji can be modified in the Customized List of the settings.".loc, tags: "")
                createLocally(string: "5. How to add the schedules\n♩ Write down the time/details to add your schedules.\n✷ Ex: Meeting with Cocoa at 3 pm\n✷ When you write something after using shortcut keys and putting a spacing, you can also add it on reminder.\n✷ Ex: -To buy iPhone charger.".loc, tags: "") { [weak self](_) in
                    guard let self = self else { return }
                    self.keyValueStore.set(true, forKey: "didAddTutorials")
                }
            }
        } catch {
            print(error)
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

    internal func emojiSorter(first: String, second: String) -> Bool {
        do {
            let firstCount = try backgroundContext.count(for: fetchRequest(with: first))
            let secondCount = try backgroundContext.count(for: fetchRequest(with: second))

            return firstCount > secondCount
        } catch {
            return false
        }
    }

    private func fetchRequest(with emoji: String) -> NSFetchRequest<Note> {
        let request:NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
        let notRemovedPredicate = NSPredicate(format: "isRemoved == false")
        let emojiPredicate = NSPredicate(format: "tags contains[cd] %@", emoji)
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [notRemovedPredicate, emojiPredicate])
        request.sortDescriptors = [sort]
        return request
    }

    static func allfetchRequest() -> NSFetchRequest<Note> {
        let request:NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
        request.predicate = NSPredicate(value: true)
        request.sortDescriptors = [sort]
        return request
    }
}
