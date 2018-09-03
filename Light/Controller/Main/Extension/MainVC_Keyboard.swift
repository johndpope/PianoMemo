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
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    internal func unRegisterKeyboardNotification(){
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        bottomView.keyboardToken?.invalidate()
        bottomView.keyboardToken = nil
        setEditButtonIfNeeded()
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            let kbHeight = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height
            else { return }
        
        bottomView.keyboardHeight = kbHeight
        bottomView.bottomViewBottomAnchor.constant = kbHeight
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
    
    private func setDoneBtn(){
        let doneBtn = BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
        doneBtn.tag = 1
        navigationItem.setRightBarButton(doneBtn, animated: true)
    }
    
    private func setEditBtn(){
        let editBtn = BarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(edit(_:)))
        editBtn.tag = 0
        navigationItem.setRightBarButton(editBtn, animated: true)
    }
    
    @IBAction func done(_ sender: Any) {
        bottomView.textView.resignFirstResponder()
    }
    
    @IBAction func edit(_ sender: Any) {
        
    }
    
}
