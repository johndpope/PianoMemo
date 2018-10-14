//
//  SplitViewDelegate.swift
//  Piano
//
//  Created by Kevin Kim on 09/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

import UIKit

class SplitViewDelegate: NSObject, UISplitViewControllerDelegate {
    func splitViewController(_ svc: UISplitViewController,
                             willShow vc: UIViewController,
                             invalidating barButtonItem: UIBarButtonItem)
    {
        if let detailView = svc.viewControllers.first as? DetailViewController {
            svc.navigationItem.backBarButtonItem = nil
            detailView.navigationItem.leftBarButtonItem = nil
        }
    }
    
    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool
    {
        guard let navigationController = primaryViewController as? UINavigationController,
            let controller = navigationController.topViewController as? MasterViewController
            else {
                return true
        }
        
        return controller.collapseDetailViewController
    }    
}
