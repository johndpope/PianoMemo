//
//  ViewController_extension.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation

extension ViewController {
    static var identifier: String {
        return String(describing: self)
    }
    
    var transparentNavigationController: TransParentNavigationController? {
        return navigationController as? TransParentNavigationController
    }
}
