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
    var syncController: Synchronizable!
    var splitViewDelegate = SplitViewDelegate()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        application.registerForRemoteNotifications()

        syncController = SyncController()
        syncController.setup()

        guard let splitVC = self.window?.rootViewController as? UISplitViewController else { return true }
        splitVC.delegate = splitViewDelegate
        if let noteListVC = (splitVC.viewControllers.first as? UINavigationController)?.topViewController as? MasterViewController {
            noteListVC.syncController = syncController
        }
        
        if let noteVC = splitVC.viewControllers.last as? DetailViewController {
            noteVC.syncController = syncController
        }
        
        splitVC.preferredDisplayMode = .allVisible

        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        let notification = CKDatabaseNotification(fromRemoteNotificationDictionary: userInfo)
        syncController.fetchChanges(in: notification.databaseScope) {
            completionHandler(.newData)
        }
    }
    
    func application(_ application: UIApplication, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        syncController.acceptShare(metadata: cloudKitShareMetadata) { [weak self] in
            guard let self = self else { return }
            self.syncController.setByPass()
            if let splitVC = self.window?.rootViewController as? UISplitViewController,
                let noteListVC = (splitVC.viewControllers.first as? UINavigationController)?.topViewController as? MasterViewController {
                
            }
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        if let detailVC = (window?.rootViewController as? UINavigationController)?.visibleViewController as? DetailViewController {
            detailVC.saveNoteIfNeeded(textView: detailVC.textView)
        } else {
            syncController.saveContext()
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        if let detailVC = (window?.rootViewController as? UINavigationController)?.visibleViewController as? DetailViewController {
            detailVC.saveNoteIfNeeded(textView: detailVC.textView)
            print("저장완료")
        } else {
            syncController.saveContext()
        }
    }
}
