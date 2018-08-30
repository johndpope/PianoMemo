//
//  UIView_Extension.swift
//  PianoNote
//
//  Created by Kevin Kim on 10/05/2018.
//  Copyright © 2018 piano. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

extension View {
    
    /**
     해당 type의 view가 subView에 속하고 있는지의 여부를 반환한다.
     - parameter type: 확인하려는 view의 type.
     */
    internal func hasSubView<T: View>(_ type: T.Type) -> Bool {
        return (viewWithTag(String(describing: type).hashValue) != nil)
    }
    
    /**
     SubViews에서 해당 type의 view를 반환한다.
     - parameter type: 가져오려는 view의 type.
     */
    internal func subView<T: View>(_ type: T.Type) -> T? {
        return viewWithTag(String(describing: type).hashValue) as? T
    }
    
    /**
     SubViews에서 해당 type의 view를 반환하되, 존재하지 않을시엔 생생하여 반환한다.
     - parameter type: 가져오려는 View의 type.
     */
    internal func createSubviewIfNeeded<T: View>(_ type: T.Type) -> T? {
        let type = String(describing: type)
        
        if let view = self.viewWithTag(type.hashValue) as? T {
            return view
        }
        
        let nib = Nib(nibName: type, bundle: nil)
        if let view = nib.instantiate(withOwner: nil, options: nil).first as? T {
            view.tag = type.hashValue
            return view
        }
        
        return nil
    }
    
}

extension UIView {
    
    static var reuseIdentifier: String {
        return String(describing: self)
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
}


extension UIView {
    internal func setEnabled(button: UIButton, isEnabled: Bool) {
        button.isEnabled = isEnabled
        button.alpha = isEnabled ? 1 : 0
        
    }
}
