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

//        syncController = SyncController()
//        syncController.setup()
//
//        if let window = window,
//            let navController = window.rootViewController as? UINavigationController,
//            let mainViewController = navController.topViewController as? MainViewController {
//            mainViewController.syncController = syncController
//        }
        
        guard let splitVC = self.window?.rootViewController as? UISplitViewController else { return true }
        splitVC.delegate = splitViewDelegate
        if let noteListVC = (splitVC.viewControllers.first as? UINavigationController)?.topViewController as? MasterViewController {
            noteListVC.backgroundContext = persistentContainer.newBackgroundContext()
        }
        
        if let noteVC = (splitVC.viewControllers.last as? UINavigationController)?.topViewController as? DetailViewController {
            noteVC.navigationItem.leftBarButtonItem = splitVC.displayModeButtonItem
            noteVC.navigationItem.leftItemsSupplementBackButton = true
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
            self.saveContext()
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        if let detailVC = (window?.rootViewController as? UINavigationController)?.visibleViewController as? DetailViewController {
            detailVC.saveNoteIfNeeded(textView: detailVC.textView)
            print("저장완료")
        } else {
            self.saveContext()
        }
    }

    // 불필요한 듯
//    func saveContext() {
//        let context = syncController.foregroundContext
//        if context.hasChanges {
//            do {
//                try context.save()
//            } catch {
//                let nserror = error as NSError
//                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
//            }
//        }
//    }
    
    
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Light")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
