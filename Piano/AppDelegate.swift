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
import Branch
import Fabric
import Crashlytics
import Firebase
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
        return UserDefaults.didMigration()
    }

    func application(
        _ application: UIApplication,
        willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        syncCoordinator = SyncCoordinator(
            container: persistentContainer,
            remoteProvider: CloudService(),
            changeProcessors: [NoteUploader(), NoteRemover(), FolderUploder(), FolderRemover()]
        )
        noteHandler = NoteHandler(context: syncCoordinator.viewContext)
        folderHandler = FolderHandler(context: syncCoordinator.viewContext)
        imageHandler = ImageHandler(context: syncCoordinator.backgroundContext)

        FirebaseApp.configure()
        Fabric.with([Branch.self, Crashlytics.self])
        Amplitude.instance()?.initializeApiKey("56dacc2dfc65516f8d85bcd3eeab087e")
        setupBranch(options: launchOptions)
        return true
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        StoreService.shared.setup()
        EditingTracker.shared.setEditingNote(note: nil)
        addObservers()
        application.registerForRemoteNotifications()
        
        guard let navController = self.window?.rootViewController as? UINavigationController,
            let masterVC = navController.topViewController as? MasterViewController else { return true }
        
        masterVC.noteHandler = noteHandler

        if let activityDictionary = launchOptions?[UIApplication.LaunchOptionsKey.userActivityDictionary] as? [AnyHashable: Any] {
            if let activity = activityDictionary["UIApplicationLaunchOptionsUserActivityKey"] as? NSUserActivity {
                //app is opened with universal link
                return handler(universalLink: activity.webpageURL!)
            }
        }
        
//        if let options = launchOptions, let _ = options[.remoteNotification] {
//            needByPass = true
//        }

        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        Branch.getInstance().application(app, open: url, options: options)
        return true
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            return handler(universalLink: userActivity.webpageURL!)
        }
        Branch.getInstance().continue(userActivity)
        return true
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        if userInfo["ck"] != nil {
//            if application.applicationState == .background {
//                needByPass = true
//            }
            let notification = CKDatabaseNotification(fromRemoteNotificationDictionary: userInfo)
            syncCoordinator.remote.fetchChanges(in: notification.databaseScope, needByPass: needByPass, needRefreshToken: false) { [unowned self]_ in
                self.needByPass = false
                completionHandler(.newData)
            }
        } else {
            Branch.getInstance().handlePushNotification(userInfo)
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
        syncCoordinator.viewContext.batchDeleteObjectsMarkedForLocalDeletion()
//        syncCoordinator.viewContext.refreshAllObjects()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
//        Logger.shared.start()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        if let detailVC = (window?.rootViewController as? UINavigationController)?.visibleViewController as? DetailViewController {
//            detailVC.view.endEditing(true)
            detailVC.pianoEditorView.saveNoteIfNeeded()
        }
        Branch.getInstance()?.logout()
    }

    func applicationWillResignActive(_ application: UIApplication) {

        if let detailVC = (window?.rootViewController as? UINavigationController)?.visibleViewController as? DetailViewController {
            detailVC.view.endEditing(true)
            detailVC.pianoEditorView.saveNoteIfNeeded()
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

    private func setupBranch(options: [UIApplication.LaunchOptionsKey: Any]? = nil) {
        Branch.getInstance()?.initSession(launchOptions: options) { [unowned self] _, error in
            guard error == nil else { return }
            func setup(id: String) {
                Branch.getInstance()?.setIdentity(id)
                Branch.getInstance()?.userCompletedAction("load")
                Referral.shared.refreshBalance()
                Referral.shared.removeLinkIfneeded()
            }

            if let id = NSUbiquitousKeyValueStore.default.string(forKey: Referral.brachUserID) {
                setup(id: id)
                return
            } else if let id = UserDefaults.standard.string(forKey: Referral.tempBranchID) {
                setup(id: id)
                return
            }

            self.syncCoordinator.remote.fetchUserID {
                if let id = NSUbiquitousKeyValueStore.default.string(forKey: Referral.brachUserID) {
                    setup(id: id)
                } else if let id = UserDefaults.standard.string(forKey: Referral.tempBranchID) {
                    setup(id: id)
                }
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
    
    func handler(universalLink url: URL) -> Bool {
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
            rootViewController.presentedViewController?.dismiss(animated: false, completion: nil)
            if let masterViewController = rootViewController.topViewController as? MasterViewController {
                masterViewController.bottomView?.textView?.becomeFirstResponder()
                return true
            }
            
            rootViewController.popToRootViewController(animated: false)
            guard let masterViewController = rootViewController.topViewController as? MasterViewController else {break}
            masterViewController.bottomView?.textView?.becomeFirstResponder()
            return true
            
        case "view":
            guard let objectIDString = dictioanry["noteId"] else {break}
            let url = URL(string: objectIDString)!
            guard let objectID = persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url) else {break}
            let object = syncCoordinator.viewContext.object(with: objectID)
            let note = object as? Note
            
            guard let rootViewController = self.window?.rootViewController as? UINavigationController else {break}
            rootViewController.presentedViewController?.dismiss(animated: false, completion: nil)
            rootViewController.popToRootViewController(animated: false)
            if let masterViewController = rootViewController.topViewController as? MasterViewController {
                masterViewController.performSegue(withIdentifier: DetailViewController.identifier, sender: note)
                return true
            }
            break
        default:
            break
        }
        return false
    }
}
