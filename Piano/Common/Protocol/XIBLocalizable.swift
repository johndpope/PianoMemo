//
//  Localizable.swift
//  Piano
//
//  Created by Kevin Kim on 17/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

protocol XIBLocalizable {
    var xibLocKey: String? { get set }
}

extension UILabel: XIBLocalizable {
    @IBInspectable var xibLocKey: String? {
        get { return nil }
        set { text = newValue?.loc }
    }
}
extension UIButton: XIBLocalizable {
    @IBInspectable var xibLocKey: String? {
        get { return nil }
        set { setTitle(newValue?.loc, for: .normal) }
    }
}

extension UIViewController: XIBLocalizable {
    @IBInspectable var xibLocKey: String? {
        get { return nil }
        set { title = newValue?.loc }
    }
}

extension UIBarButtonItem: XIBLocalizable {
    @IBInspectable var xibLocKey: String? {
        get { return nil }
        set { title = newValue?.loc }
    }
}
