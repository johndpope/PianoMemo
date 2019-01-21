//
//  ViewController_extension.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

extension ViewController {
    static var identifier: String {
        return String(describing: self)
    }

    var transparentNavigationController: TransParentNavigationController? {
        return navigationController as? TransParentNavigationController
    }
}

extension ViewController {
    var isVisible: Bool {
        return self.isViewLoaded && self.view.window != nil
    }

    func showActivityIndicator() {
        Application.shared.beginIgnoringInteractionEvents()
        let indicator = UIActivityIndicatorView(style: .gray)
        indicator.tag = Preference.indicatorTag
        view.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        indicator.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        indicator.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        indicator.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        indicator.hidesWhenStopped = true
        indicator.startAnimating()
    }

    func hideActivityIndicator() {
        view.viewWithTag(Preference.indicatorTag)?.removeFromSuperview()
        Application.shared.endIgnoringInteractionEvents()
    }

}
