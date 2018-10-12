//
//  DetailVC_Keyboard.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 2..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

extension DetailViewController {
    
    internal func registerAllNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeDidChangeNotification(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    internal func unRegisterAllNotifications(){
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func contentSizeDidChangeNotification(_ notification: Notification) {
        textView.setup(note: note)
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        
        setNavigationItems(state: state)
        textView.setInset(contentInsetBottom: 0)
        keyboardToken?.invalidate()
        keyboardToken = nil
    }
    
    @objc func keyboardDidHide(_ notification: Notification) {

    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            let kbHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height,
            let _ = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
            else { return }
        let height = kbHeight - (UIScreen.main.bounds.height - defaultToolbar.frame.origin.y)
        textView.setInset(contentInsetBottom: height)
        setNavigationItems(state: .typing)
        textAccessoryBottomAnchor.constant = height
        view.layoutIfNeeded()
        
        keyboardToken = UIApplication.shared.windows[1].subviews.first?.subviews.first?.layer.observe(\.position, changeHandler: { [weak self](layer, change) in
            guard let `self` = self else { return }
            
            self.textAccessoryBottomAnchor.constant = max(self.view.bounds.height - layer.frame.origin.y, 0)
            self.view.layoutIfNeeded()
        })
    }
}
