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
import Firebase
import Fabric
import Crashlytics
import Amplitude_iOS

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var syncCoordinator: SyncCoordinator!
    var noteHandler: NoteHandlable!
    var folderHandler: FolderHandlable!
    var imageHandler: ImageHandlable!
    var needByPass = false

    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }

    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        print("shouldRestoreApplicationState🌞")
        return true
    }

    func application(
        _ application: UIApplication,
        willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        syncCoordinator = SyncCoordinator(
            container: persistentContainer,
            remoteProvider: CloudService(),
            changeProcessors: [NoteUploader(), NoteRemover(), FolderUploder(), FolderRemover(), ImageUploader(), ImageRemover()]
        )
        noteHandler = NoteHandler(context: syncCoordinator.viewContext)
        folderHandler = FolderHandler(context: syncCoordinator.viewContext)
        imageHandler = ImageHandler(context: syncCoordinator.backgroundContext)
        
        FirebaseApp.configure()
        Fabric.with([Crashlytics.self])
        //Amplitude.instance()?.initializeApiKey("56dacc2dfc65516f8d85bcd3eeab087e")
        return true
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        StoreService.shared.setup()
        EditingTracker.shared.setEditingNote(note: nil)
        addObservers()
        application.registerForRemoteNotifications()

        guard let navController = self.window?.rootViewController as? UINavigationController, let noteCollectionVC = navController.topViewController as? NoteCollectionViewController else { return true }

        noteCollectionVC.noteHandler = noteHandler
        noteCollectionVC.imageHandler = imageHandler
        noteCollectionVC.folderHadler = folderHandler
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
        if let blockVC = (window?.rootViewController as? UINavigationController)?.visibleViewController as? BlockTableViewController {
            blockVC.view.endEditing(true)
            blockVC.saveNoteIfNeeded(needToSave: true)
        } else if let tagPickerVC = (window?.rootViewController as? UINavigationController)?.visibleViewController as? TagPickerViewController {
            tagPickerVC.dismiss(animated: true, completion: nil)
        } else if let customizeBulletTableVC = (window?.rootViewController as? UINavigationController)?.visibleViewController as? CustomizeBulletViewController {
            customizeBulletTableVC.view.endEditing(true)
        }
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        syncCoordinator.viewContext.refreshAllObjects()
    }

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Light")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()

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
