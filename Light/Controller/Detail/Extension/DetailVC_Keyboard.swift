//
//  DetailVC_Keyboard.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 2..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

extension DetailViewController {
    
    var bottomHeight: CGFloat {
        return 100
    }
    
    internal func registerKeyboardNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(_:)), name: .UIKeyboardDidHide, object: nil)
    }
    
    internal func unRegisterKeyboardNotification(){
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardDidHide(_ notification: Notification) {
        setNavigationBar(state: .normal)
        
        textView.contentInset.bottom = bottomHeight
        textView.scrollIndicatorInsets.bottom = bottomHeight
        //데이터 리셋
        detailInputView.type = nil
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            var kbHeight = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height,
            let _ = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval
            else { return }
        
        
        kbHeight = kbHeight < 200 ? 300 : kbHeight
        self.kbHeight = kbHeight
        
        textView.contentInset.bottom = kbHeight + bottomHeight
        textView.scrollIndicatorInsets.bottom = kbHeight + bottomHeight
        
        setNavigationBar(state: .typing)
    }
}
