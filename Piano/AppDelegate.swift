//
//  AppDelegate.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import UserNotifications
import Amplitude_iOS
import Bugsnag

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var needByPass = false

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Light")
        let description = NSPersistentStoreDescription()
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            container.viewContext.automaticallyMergesChangesFromParent = true
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    lazy var syncCoordinator: SyncCoordinator = SyncCoordinator(
        container: persistentContainer,
        remoteProvider: CloudService(),
        changeProcessors: [
            NoteUploader(),
            NoteRemover(),
            FolderUploder(),
            FolderRemover(),
            ImageUploader(),
            ImageRemover()
        ]
    )
    lazy var noteHandler: NoteHandlable = NoteHandler(context: syncCoordinator.viewContext)
    lazy var folderHandler: FolderHandlable = FolderHandler(context: syncCoordinator.viewContext)
    lazy var imageHandler: ImageHandlable = ImageHandler(context: syncCoordinator.backgroundContext)
    lazy var imageCache = NSCache<NSString, UIImage>()

    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }

    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        print("shouldRestoreApplicationState🌞")
        return true
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        StoreService.shared.setup()
        EditingTracker.shared.setEditingNote(note: nil)
        addObservers()
        Bugsnag.start(withApiKey: "de7feef68d708b57e5c3cc3c6b067079")
        application.registerForRemoteNotifications()

        #if DEBUG
        //UserDefaults.standard.set(false, forKey: "didFinishTutorial")
        #endif

//        if !UserDefaults.standard.bool(forKey: "didFinishTutorial") {
//            let storyboard = UIStoryboard(name: "Tutorial", bundle: nil)
//            let initialViewController = storyboard.instantiateViewController(withIdentifier: "fianlVC") as! TutorialFinishViewController
//            self.window?.rootViewController = initialViewController
//            self.window?.makeKeyAndVisible()
//            return true
//        }

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return deepLinkHandler(link: url)
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return true
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        guard userInfo["ck"] != nil else { return }
//        if application.applicationState == .background {
//            needByPass = true
//        }
        let notification = CKDatabaseNotification(fromRemoteNotificationDictionary: userInfo)
        syncCoordinator.remote.fetchChanges(in: notification.databaseScope, needByPass: needByPass, needRefreshToken: false) { [unowned self]_ in
            self.needByPass = false
            completionHandler(.newData)
        }
    }

    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {

        needByPass = true
//        storageService.remote.acceptShare(metadata: cloudKitShareMetadata) { [unowned self] in
//            self.storageService.remote
//                .requestApplicationPermission { _, _ in }
//        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        if let blockTableVC = (window?.rootViewController as? UINavigationController)?.visibleViewController as? BlockTableViewController {
            blockTableVC.saveNoteIfNeeded()
        }
        syncCoordinator.viewContext.saveOrRollback()
        syncCoordinator.viewContext.batchDeleteObjectsMarkedForLocalDeletion()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
    }

    func applicationWillTerminate(_ application: UIApplication) {

    }

    func applicationWillResignActive(_ application: UIApplication) {

    }

    /// 기기의 메모리가 부족할 때 불리는 메서드 입니다.
    /// viewContext에 있는 코어데이터 객체들이 메모리에서 해제됩니다.
    ///
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        syncCoordinator.viewContext.refreshAllObjects()
    }

}

extension AppDelegate {
    private func addObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(synchronizeKeyStore(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: nil
        )
    }

    @objc func synchronizeKeyStore(_ notificaiton: Notification) {
        KeyValueStore.default.synchronize()
        NotificationCenter.default.post(name: .refreshTextAccessory, object: nil)
    }

    private func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("Permission granted: \(granted)")
            guard granted else { return }
            self.getNotificationSettings()
        }
    }

    private func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

}

extension AppDelegate {
    func decodeNote(url: URL, completion: @escaping (Note?) -> Void) {
        if let id = persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url) {
            persistentContainer.viewContext.perform {
                do {
                    let object = try self.persistentContainer.viewContext.existingObject(with: id)
                    if let note = object as? Note {
                        if note.isRemoved {
                            completion(nil)
                        } else {
                            completion(note)
                        }
                    } else {
                        completion(nil)
                    }
                } catch {
                    print(error)
                    completion(nil)
                }
            }
        }
    }
}

extension AppDelegate {
    func deepLinkHandler(link url: URL) -> Bool {
        guard let component = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let queryItems = component.queryItems else {
                return false
        }
        var dictioanry: [String: String] = [:]
        for item in queryItems {
            guard let value = item.value else {continue}
            dictioanry[item.name] = value
        }

        guard let action = dictioanry["action"] else {return false}
        switch action {
        case "create":
            guard let rootViewController = self.window?.rootViewController as? UINavigationController else {break}
            if let presentedVC = rootViewController.presentedViewController {
                if let navigation = presentedVC as? UINavigationController,
                    let _ = navigation.viewControllers[0] as? SmartWritingViewController {
                    //smart writer is already opened
                    return true
                }
                presentedVC.dismiss(animated: false, completion: nil)
            }

            if let noteCollectionVC = rootViewController.topViewController as? NoteCollectionViewController {
                DispatchQueue.main.async {
                    noteCollectionVC.performSegue(withIdentifier: SmartWritingViewController.identifier, sender: nil)
                }
                return true
            }

            rootViewController.popToRootViewController(animated: false)
            guard let noteCollectionVC = rootViewController.topViewController as? NoteCollectionViewController else {return false}
            DispatchQueue.main.async {
                noteCollectionVC.performSegue(withIdentifier: SmartWritingViewController.identifier, sender: nil)
            }
            return true

        case "view":
            guard let objectIDString = dictioanry["noteId"] else {break}
            let url = URL(string: objectIDString)!
            guard let objectID = persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url) else {break}
            let object = syncCoordinator.viewContext.object(with: objectID)
            let note = object as? Note

            guard let rootViewController = self.window?.rootViewController as? UINavigationController else {break}
            if let presentedVC = rootViewController.presentedViewController {
                presentedVC.dismiss(animated: false, completion: nil)
            }

            if let blockTableVC = rootViewController.topViewController as? BlockTableViewController {
                //block table view is already on top, replace current note
                blockTableVC.note = note
                DispatchQueue.main.async {
                    blockTableVC.setup()
                }
                return true
            }

            if let noteCollectionVC = rootViewController.topViewController as? NoteCollectionViewController {
                noteCollectionVC.performSegue(withIdentifier: BlockTableViewController.identifier, sender: note)
                return true
            }

            rootViewController.popToRootViewController(animated: false)
            guard let noteCollectionVC = rootViewController.topViewController as? NoteCollectionViewController else {return false}
            DispatchQueue.main.async {
                noteCollectionVC.performSegue(withIdentifier: BlockTableViewController.identifier, sender: note)
            }
            return true
        default:
            break
        }
        return false
    }
}
