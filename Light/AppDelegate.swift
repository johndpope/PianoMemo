//
//  AppDelegate.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import CoreData
import GoogleSignIn
import Cloud

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var cloudManager: CloudManager?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        cloudManager = CloudManager(cloud: CKContainer.default(), coreData: persistentContainer)
        application.registerForRemoteNotifications()
        
        GIDSignIn.sharedInstance().clientID = "717542171790-q87k0jrps9n4r6bn4ak45iohdrar80dj.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().scopes.append("https://mail.google.com/")
        GIDSignIn.sharedInstance().signInSilently()
        
        if let window = window,
            let navC = window.rootViewController as? UINavigationController,
            let mainViewController = navC.topViewController as? MainViewController {
            mainViewController.persistentContainer = self.persistentContainer
        }
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance().handle(url as URL?,
                                                 sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                                                 annotation: options[UIApplication.OpenURLOptionsKey.annotation])
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        cloudManager?.download.operate(with: userInfo, completionHandler)
    }

    private func application(_ application: UIApplication, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        cloudManager?.acceptShared.operate(with: cloudKitShareMetadata)
        cloudManager?.acceptShared.perShareCompletionBlock = { (metadata, share, error) in

        }
        cloudManager?.acceptShared.acceptSharesCompletionBlock = { error in

        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        if let detailVC = (window?.rootViewController as? UINavigationController)?.visibleViewController as? DetailViewController {
            detailVC.saveNoteIfNeeded()
        } else {
            self.saveContext()
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        if let detailVC = (window?.rootViewController as? UINavigationController)?.visibleViewController as? DetailViewController {
            detailVC.saveNoteIfNeeded()
        } else {
            self.saveContext()
        }
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Light")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func saveContext() {
        let context = persistentContainer.viewContext
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
