//
//  TextNotification.swift
//  Piano
//
//  Created by Kevin Kim on 28/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

struct TextNotification {
    static func showMessage(navigationController: NavigationController?, message: String) {
        guard let navController = navigationController,
            let navView = navController.view,
            let messageView = navController.view.createSubviewIfNeeded(NotificationView.self) else { return }
        let statusBarHeight = Application.shared.statusBarFrame.height
        let navHeight = navController.navigationBar.bounds.height + statusBarHeight
        
        messageView.label.text = message
        messageView.statusBarHeightAnchor.constant = statusBarHeight
        
        navView.addSubview(messageView)
        messageView.translatesAutoresizingMaskIntoConstraints = false
        messageView.leadingAnchor.constraint(equalTo: navView.leadingAnchor).isActive = true
        messageView.trailingAnchor.constraint(equalTo: navView.trailingAnchor).isActive = true
        let topAnchor = messageView.topAnchor.constraint(equalTo: navView.topAnchor, constant: 0)
        topAnchor.isActive = true
        messageView.heightAnchor.constraint(equalToConstant: navHeight).isActive = true
        navView.layoutIfNeeded()
        
        CATransaction.setCompletionBlock {
            View.animate(withDuration: 0.3, delay: 1, options: [], animations: {
                topAnchor.constant = -navHeight
                navView.layoutIfNeeded()
            }) { (bool) in
                if bool {
                    messageView.removeFromSuperview()
                }
            }
        }
        
        
        
    }
    
}
