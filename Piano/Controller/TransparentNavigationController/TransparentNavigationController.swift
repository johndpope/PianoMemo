//
//  TransparentNavigationController.swift
//  Piano
//
//  Created by Kevin Kim on 20/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class TransParentNavigationController: UINavigationController {

    let navColor = UIColor(hex6: "fafafa")
    let toolbarColor = UIColor(hex6: "fff")
    private var notiViewHeightAnchor: NSLayoutConstraint!
    private var isPresenting = false

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.shadowImage = UIImage()
        navigationBar.setBackgroundImage(#imageLiteral(resourceName: "Rectangle"), for: .default)
//        navigationBar.barTintColor = Color.white.withAlphaComponent(0.97)

        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        toolbar.setBackgroundImage(#imageLiteral(resourceName: "Rectangle"), forToolbarPosition: .any, barMetrics: .default)
//        toolbar.backgroundColor = toolbarColor

//        navigationBar.largeTitleTextAttributes = [.foregroundColor: Color.darkGray]
//        navigationBar.titleTextAttributes = [.foregroundColor: Color.darkGray]

        guard let notiView = view.createSubviewIfNeeded(NotificationView.self) else { return }
        self.view.addSubview(notiView)
        notiView.translatesAutoresizingMaskIntoConstraints = false
        notiView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        notiView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        notiView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor).isActive = true
        notiViewHeightAnchor = notiView.heightAnchor.constraint(equalToConstant: 0)
        notiViewHeightAnchor.isActive = true
    }

    internal func show(message: String, textColor: Color? = UIColor.white, color: Color? = nil) {
        guard let notiView = view.subView(NotificationView.self),
            !isPresenting else { return }

        if let color = color {
            notiView.backgroundColor = color.withAlphaComponent(0.85)
        }
        notiView.label.text = message

        if let textColor = textColor {
            notiView.label.textColor = textColor
        }

        self.notiViewHeightAnchor.constant = 0

        CATransaction.setCompletionBlock { [weak self] in
            guard let self = self else { return }
            self.isPresenting = true
            self.notiViewHeightAnchor.constant = 0
            View.animate(withDuration: 0.2, animations: {
                self.notiViewHeightAnchor.constant = 65.5
                self.view.layoutIfNeeded()
            }, completion: { _ in
                View.animate(withDuration: 0.2, delay: 1.0, options: [], animations: { [weak self] in
                    guard let self = self else { return }
                    self.notiViewHeightAnchor.constant = 0
                    self.view.layoutIfNeeded()
                    }, completion: { _ in
                        self.isPresenting = false
                })
            })
        }
    }
}
