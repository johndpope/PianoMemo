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
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        application.registerForRemoteNotifications()

        syncController = SyncController()
        syncController.setup()
        
        if let window = window,
            let navController = window.rootViewController as? UINavigationController,
            let mainViewController = navController.topViewController as? MainViewController {
            mainViewController.syncController = syncController
        }
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        let notification = CKDatabaseNotification(fromRemoteNotificationDictionary: userInfo)
        syncController.fetchChanges(in: notification.databaseScope) {
            completionHandler(.newData)
        }
    }
    
    func application(_ application: UIApplication, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        syncController.acceptShare(metadata: cloudKitShareMetadata) {
            // TODO:
            print("didAccept")
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
