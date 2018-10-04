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

var cloudManager: CloudManager?

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var syncController: Synchronizable!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        application.registerForRemoteNotifications()

        syncController = SyncController()
        if let window = window,
            let navC = window.rootViewController as? UINavigationController,
            let mainViewController = navC.topViewController as? MainViewController {
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

            print("didAccept")
        }

//        cloudManager?.acceptShared.operate(with: cloudKitShareMetadata)
//        cloudManager?.acceptShared.perShareCompletionBlock = { (metadata, share, sError) in
//            cloudManager?.download.operate()
//            cloudManager?.share.targetShare = share
//            CKContainer.default().requestApplicationPermission(.userDiscoverability) { (_, _) in}
//        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        if let detailVC = (window?.rootViewController as? UINavigationController)?.visibleViewController as? DetailViewController {
            detailVC.saveNoteIfNeeded(textView: detailVC.textView)
        } else {
            self.saveContext()
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        if let detailVC = (window?.rootViewController as? UINavigationController)?.visibleViewController as? DetailViewController {
            detailVC.saveNoteIfNeeded(textView: detailVC.textView)
        } else {
            self.saveContext()
        }
    }

    // 불필요한 듯
    func saveContext() {
        let context = syncController.foregroundContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
