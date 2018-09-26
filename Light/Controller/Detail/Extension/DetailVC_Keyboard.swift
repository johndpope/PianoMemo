//
//  DetailVC_Keyboard.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 2..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

extension DetailViewController {
    
    internal func registerKeyboardNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    internal func unRegisterKeyboardNotification(){
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        setNavigationBar(state: .normal)
        textView.contentInset.bottom = completionToolbar.bounds.height
        textView.scrollIndicatorInsets.bottom = completionToolbar.bounds.height
        keyboardToken?.invalidate()
        keyboardToken = nil
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            let kbHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height,
            let _ = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
            else { return }
        
        textView.contentInset.bottom = kbHeight
        textView.scrollIndicatorInsets.bottom = kbHeight
        
        setNavigationBar(state: .typing)
        textAccessoryBottomAnchor.constant = kbHeight
        view.layoutIfNeeded()
        
        keyboardToken = UIApplication.shared.windows[1].subviews.first?.subviews.first?.layer.observe(\.position, changeHandler: { [weak self](layer, change) in
            guard let `self` = self else { return }
            
            self.textAccessoryBottomAnchor.constant = max(self.view.bounds.height - layer.frame.origin.y, 0)
            self.view.layoutIfNeeded()
        })
    }
}
