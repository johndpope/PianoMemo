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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var storageService: StorageService!
    var splitViewDelegate = SplitViewDelegate()
    var needByPass = false

    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }

    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return true
    }

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        storageService = StorageService()
        storageService.setup()
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        application.registerForRemoteNotifications()

        guard let splitVC = self.window?.rootViewController as? UISplitViewController else { return true }
        splitVC.delegate = splitViewDelegate
        if let noteListVC = (splitVC.viewControllers.first as? UINavigationController)?.topViewController as? MasterViewController {
            noteListVC.storageService = storageService
        }
        
        if let noteVC = splitVC.viewControllers.last as? DetailViewController {
            noteVC.storageService = storageService
        }
        
        splitVC.preferredDisplayMode = .allVisible

        return true
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        let notification = CKDatabaseNotification(fromRemoteNotificationDictionary: userInfo)
        storageService.remote.fetchChanges(in: notification.databaseScope, needByPass: needByPass) {
            [unowned self] in
            self.needByPass = false
            completionHandler(.newData)
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
    
    func applicationWillTerminate(_ application: UIApplication) {
        if let detailVC = (window?.rootViewController as? UINavigationController)?.visibleViewController as? DetailViewController {
            detailVC.saveNoteIfNeeded(textView: detailVC.textView)
        } else {
            storageService.local.saveContext()
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        if let detailVC = (window?.rootViewController as? UINavigationController)?.visibleViewController as? DetailViewController {
            detailVC.saveNoteIfNeeded(textView: detailVC.textView)
            print("저장완료")
        } else {
            storageService.local.saveContext()
        }
    }
}
