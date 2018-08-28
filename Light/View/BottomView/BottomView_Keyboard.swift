//
//  BottomView_Keyboard.swift
//  Piano
//
//  Created by Kevin Kim on 2018. 8. 19..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

extension BottomView {
    internal func registerKeyboardNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    internal func unRegisterKeyboardNotification(){
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        keyboardToken?.invalidate()
        keyboardToken = nil
        mainViewController?.bottomView(self, keyboardWillHide: 0)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            let kbHeight = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height
            else { return }
        
        keyboardHeight = kbHeight
        bottomConstraint.constant = kbHeight
        superview?.layoutIfNeeded()
        
        keyboardToken = UIApplication.shared.windows[1].subviews.first?.subviews.first?.layer.observe(\.position, changeHandler: { [weak self](layer, change) in
            guard let `self` = self,
                let superView = self.superview else { return }
            
            self.bottomConstraint.constant = max(superView.bounds.height - layer.frame.origin.y, 0)
            superView.layoutIfNeeded()
        })
        
        mainViewController?.bottomView(self, keyboardWillShow: kbHeight)
        
    }
}
