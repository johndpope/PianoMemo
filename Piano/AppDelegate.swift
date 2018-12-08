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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var storageService: StorageService!
    var needByPass = false

    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }

    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        print("shouldRestoreApplicationState🌞")
        return UserDefaults.didContentMigration()
    }

    func application(
        _ application: UIApplication,
        willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        storageService = StorageService()
        storageService.setup()

        FirebaseApp.configure()
        Fabric.with([Branch.self, Crashlytics.self])

        Branch.getInstance()?.initSession(launchOptions: launchOptions) {
            [unowned self] params, error in
            guard error == nil else { return }
            func setup(id: String) {
                Branch.getInstance()?.setIdentity(id)
                Branch.getInstance()?.userCompletedAction("load")
                Referral.shared.refreshBalance()
            }
            if let recordName = UserDefaults.getUserIdentity()?.userRecordID?.recordName {
                setup(id: recordName)
                return
            }
            self.storageService.remote.requestUserID {
                if let recordName = UserDefaults.getUserIdentity()?.userRecordID?.recordName {
                    setup(id: recordName)
                } else {
                    if let id = UserDefaults.standard.string(forKey: "branchUserIdentifier") {
                        setup(id: id)
                    } else {
                        let newID = UUID().uuidString
                        UserDefaults.standard.set(newID, forKey: "branchUserIdentifier")
                        setup(id: newID)
                    }
                }
            }
        }
        return true
    }
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

//        StoreService.shared.setup()
        application.registerForRemoteNotifications()
        
        guard let navController = self.window?.rootViewController as? UINavigationController,
            let masterVC = navController.topViewController as? MasterViewController else { return true }
        
//        registerForPushNotifications()
        masterVC.storageService = storageService
        
//        if let options = launchOptions, let _ = options[.remoteNotification] {
//            needByPass = true
//        }

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        Branch.getInstance().application(app, open: url, options: options)
        return true
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        Branch.getInstance().continue(userActivity)
        return true
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        if userInfo["ck"] != nil {
//            if application.applicationState == .background {
//                needByPass = true
//            }
            let notification = CKDatabaseNotification(fromRemoteNotificationDictionary: userInfo)
            storageService.remote.fetchChanges(in: notification.databaseScope, needByPass: needByPass) {
                [unowned self] in
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
        storageService.remote.acceptShare(metadata: cloudKitShareMetadata) { [unowned self] in
            self.storageService.remote
                .requestApplicationPermission { _, _ in }
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
//        Logger.shared.start()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        if let detailVC = (window?.rootViewController as? UINavigationController)?.visibleViewController as? DetailViewController {
//            detailVC.view.endEditing(true)
            detailVC.pianoEditorView.saveNoteIfNeeded()
        } else {
            storageService.local.saveContext()
        }
        Branch.getInstance()?.logout()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
//        Logger.shared.stop()

        if let detailVC = (window?.rootViewController as? UINavigationController)?.visibleViewController as? DetailViewController {
            detailVC.view.endEditing(true)
            detailVC.pianoEditorView.saveNoteIfNeeded()
        } else if let tagPickerVC = (window?.rootViewController as? UINavigationController)?.visibleViewController as? TagPickerViewController {
            tagPickerVC.dismiss(animated: true, completion: nil)
        } else if let customizeBulletTableVC = (window?.rootViewController as? UINavigationController)?.visibleViewController as? CustomizeBulletViewController {
            customizeBulletTableVC.view.endEditing(true)
        }
        else {
            storageService.local.saveContext()
        }
    }
}

extension AppDelegate {
    private func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
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
