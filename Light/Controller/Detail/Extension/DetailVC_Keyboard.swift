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
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(_:)), name: .UIKeyboardDidHide, object: nil)
    }
    
    internal func unRegisterKeyboardNotification(){
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardDidHide(_ notification: Notification) {
        keyboardToken?.invalidate()
        keyboardToken = nil
        setNavigationBar(isTyping: false)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            var kbHeight = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height,
            let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval
            else { return }
        
        
        kbHeight = kbHeight < 200 ? 300 : kbHeight
        self.kbHeight = kbHeight
        
        UIView.animate(withDuration: duration) { [weak self] in
            self?.bottomViewBottomAnchor.constant = kbHeight
            self?.view.layoutIfNeeded()
        }
        
        keyboardToken = UIApplication.shared.windows[1].subviews.first?.subviews.first?.layer.observe(\.position, changeHandler: { [weak self](layer, change) in
            guard let `self` = self else { return }
            
            self.bottomViewBottomAnchor.constant = max(self.view.bounds.height - layer.frame.origin.y, 0)

            self.view.layoutIfNeeded()
        })
        
        setNavigationBar(isTyping: true)
    }
}
