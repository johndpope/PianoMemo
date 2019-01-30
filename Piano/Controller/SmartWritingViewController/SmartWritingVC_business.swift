//
//  SmartWritingVC_business.swift
//  Piano
//
//  Created by Kevin Kim on 30/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension SmartWritingViewController {
    internal func setHiddenGuideViews(isHidden: Bool) {
        suggestionGuideView.isHidden = isHidden
        suggestionGuideButton.isSelected = !isHidden
    }
    
    internal func registerAllNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: Responder.keyboardWillShowNotification, object: nil)
    }
    
    internal func unRegisterAllNotification() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            let kbHeight = (userInfo[Responder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height
            else { return }
        
        bottomViewBottomAnchor.constant = kbHeight
    }
}
