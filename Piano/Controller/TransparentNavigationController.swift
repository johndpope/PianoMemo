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
    private var notiViewHeightAnchor: NSLayoutConstraint!
    private var isPresenting = false
    
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
        notiViewHeightAnchor = notiView.heightAnchor.constraint(equalToConstant: 0)
        notiViewHeightAnchor.isActive = true
    }
    
    internal func show(message: String, color: Color? = nil) {
        guard let notiView = view.subView(NotificationView.self),
            !isPresenting else { return }

        if let color = color {
            notiView.backgroundColor = color.withAlphaComponent(0.85)
        }
        notiView.label.text = message
        self.notiViewHeightAnchor.constant = 0
        
        CATransaction.setCompletionBlock { [weak self] in
            guard let self = self else { return }
            self.isPresenting = true
            self.notiViewHeightAnchor.constant = 0
            View.animate(withDuration: 0.2, animations: {
                self.notiViewHeightAnchor.constant = 65.5
                self.view.layoutIfNeeded()
            }) { (_) in
                View.animate(withDuration: 0.2, delay: 1.0, options: [], animations: { [weak self] in
                    guard let `self` = self else { return }
                    self.notiViewHeightAnchor.constant = 0
                    self.view.layoutIfNeeded()
                    }, completion: { _ in
                        self.isPresenting = false
                })
            }
        }
    }
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: nil) {[weak self] (_) in
            guard let self = self else { return }
            self.setStatusBarView()

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
