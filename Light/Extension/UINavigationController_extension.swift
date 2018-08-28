//
//  UINavigationController_extension.swift
//  Block
//
//  Created by Kevin Kim on 2018. 7. 24..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

extension NavigationController {
    
    internal func appearCopyNotificationView() {
        guard let notiView = self.view.createSubviewIfNeeded(NotificationView.self) else { return }
        view.addSubview(notiView)
        notiView.labelHeightAnchor.constant = navigationBar.bounds.height
        notiView.translatesAutoresizingMaskIntoConstraints = false
        let topAnchor = notiView.topAnchor.constraint(equalTo: view.topAnchor)
        let leadingAnchor = notiView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let trailingAnchor = notiView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        let height = navigationBar.bounds.height + UIApplication.shared.statusBarFrame.height
        let heightAnchor = notiView.heightAnchor.constraint(equalToConstant: height)
        NSLayoutConstraint.activate([topAnchor, leadingAnchor, trailingAnchor, heightAnchor])
        
        self.view.layoutIfNeeded()
        
        disappearFinishCopyView(topAnchor: topAnchor)
    }
    
    private func disappearFinishCopyView(topAnchor: NSLayoutConstraint) {
        let height = navigationBar.bounds.height + UIApplication.shared.statusBarFrame.height
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) { [weak self] in
            topAnchor.constant = -height
            self?.view.layoutIfNeeded()
        }
        
        animator.addCompletion { [weak self] (_) in
            guard let notiView = self?.view.subView(NotificationView.self) else { return }
            notiView.removeFromSuperview()
        }
        
        animator.startAnimation(afterDelay: 1)
    }
}
