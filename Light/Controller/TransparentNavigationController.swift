//
//  TransparentNavigationController.swift
//  Piano
//
//  Created by Kevin Kim on 20/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class TransParentNavigationController: UINavigationController {
    
    let navColor = UIColor.white.withAlphaComponent(0.97)
    var messageViewHeightAnchor: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        navigationBar.shadowImage = UIImage()
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.backgroundColor = navColor
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        toolbar.backgroundColor = navColor
        
        setStatusBarView()
        
        guard let notiView = view.createSubviewIfNeeded(NotificationView.self) else { return }
        self.view.addSubview(notiView)
        notiView.translatesAutoresizingMaskIntoConstraints = false
        notiView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        notiView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        notiView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor).isActive = true
        messageViewHeightAnchor = notiView.heightAnchor.constraint(equalToConstant: 0)
        messageViewHeightAnchor.isActive = true
    }
    
    internal func show(message: String, color: Color? = nil) {
        guard let messageView = view.subView(NotificationView.self) else { return }
        if let color = color {
            messageView.backgroundColor = color
        }
        CATransaction.setCompletionBlock { [weak self] in
            guard let `self` = self else { return }
            messageView.label.text = message
            self.messageViewHeightAnchor.constant = 0
            View.animate(withDuration: 0.2, animations: {
                self.messageViewHeightAnchor.constant = 30
                self.view.layoutIfNeeded()
            }) { (bool) in
                guard bool else { return }
                View.animate(withDuration: 0.2, delay: 1.0, options: [], animations: { [weak self] in
                    guard let `self` = self else { return }
                    self.messageViewHeightAnchor.constant = 0
                    self.view.layoutIfNeeded()
                    }, completion: nil)
            }
        }
    }
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: nil) {[weak self] (_) in
            self?.setStatusBarView()
        }
    }
    
    private func setStatusBarView() {
        
        if UIApplication.shared.statusBarFrame.height != 0 {
            guard let statusBarView = view.createSubviewIfNeeded(StatusBarView.self) else {return}
            statusBarView.backgroundColor = navColor
            statusBarView.frame = UIApplication.shared.statusBarFrame
            view.addSubview(statusBarView)
        } else {
            view.subView(StatusBarView.self)?.removeFromSuperview()
        }
    }
}
