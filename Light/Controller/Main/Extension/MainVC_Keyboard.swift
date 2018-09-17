//
//  MainVC_Keyboard.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 2..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

extension MainViewController {
    internal func registerKeyboardNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    internal func unRegisterKeyboardNotification(){
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        bottomView.keyboardToken?.invalidate()
        bottomView.keyboardToken = nil
        setEditButtonIfNeeded()
        collectionView.contentInset.bottom = bottomView.bounds.height
        collectionView.scrollIndicatorInsets.bottom = bottomView.bounds.height
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            let kbHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height
            else { return }
        
        bottomView.keyboardHeight = kbHeight
        bottomView.bottomViewBottomAnchor.constant = kbHeight
        collectionView.contentInset.bottom = kbHeight + bottomView.bounds.height
        collectionView.scrollIndicatorInsets.bottom = kbHeight + bottomView.bounds.height
        view.layoutIfNeeded()
        
        bottomView.keyboardToken = UIApplication.shared.windows[1].subviews.first?.subviews.first?.layer.observe(\.position, changeHandler: { [weak self](layer, change) in
            guard let `self` = self else { return }
            
            self.bottomView.bottomViewBottomAnchor.constant = max(self.view.bounds.height - layer.frame.origin.y, 0)
            self.view.layoutIfNeeded()
        })
        
        setDoneButtonIfNeeded()
        
    }
}


extension MainViewController {
    
    enum BarButtonType: Int {
        case edit = 0
        case done = 1
    }
    
    private func setDoneButtonIfNeeded() {
        if navigationItem.rightBarButtonItem == nil {
            setDoneBtn()
            return
        }
        
        if let rightBarItem = navigationItem.rightBarButtonItem,
            let type = BarButtonType(rawValue: rightBarItem.tag),
            type != .done {
            setDoneBtn()
            return
        }
        
    }
    
    private func setEditButtonIfNeeded() {
        if navigationItem.rightBarButtonItem == nil {
            setEditBtn()
        }
        
        if let rightBarItem = navigationItem.rightBarButtonItem,
            let type = BarButtonType(rawValue: rightBarItem.tag),
            type != .edit {
            setEditBtn()
        }
    }
    
}
