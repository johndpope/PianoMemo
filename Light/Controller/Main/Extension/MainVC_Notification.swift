//
//  MainVC_Keyboard.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 2..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

extension MainViewController {
    
    internal func registerAllNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeStatusBarOrientation(_:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    internal func unRegisterAllNotification(){
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func didChangeStatusBarOrientation(_ notification: Notification) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    internal func initialContentInset(){
        collectionView.contentInset.bottom = bottomView.bounds.height
        collectionView.scrollIndicatorInsets.bottom = bottomView.bounds.height
    }
    
    private func setContentInsetForKeyboard() {
        collectionView.contentInset.bottom = kbHeight// + bottomView.bounds.height
        collectionView.scrollIndicatorInsets.bottom = kbHeight// + bottomView.bounds.height
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        bottomView.keyboardToken?.invalidate()
        bottomView.keyboardToken = nil
        initialContentInset()
        
        let trashBtn = BarButtonItem(title: "🗑", style: .plain, target: self, action: #selector(trash(_:)))
        navigationItem.setRightBarButton(trashBtn, animated: false)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            let kbHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height
            else { return }
        
        let doneBtn = BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
        navigationItem.setRightBarButton(doneBtn, animated: false)
        
        bottomView.keyboardHeight = kbHeight
        bottomView.bottomViewBottomAnchor.constant = kbHeight
        setContentInsetForKeyboard()
        view.layoutIfNeeded()
        self.kbHeight = kbHeight
        
        bottomView.keyboardToken = UIApplication.shared.windows[1].subviews.first?.subviews.first?.layer.observe(\.position, changeHandler: { [weak self](layer, change) in
            guard let `self` = self else { return }
            
            self.bottomView.bottomViewBottomAnchor.constant = max(self.view.bounds.height - layer.frame.origin.y, 0)
            self.view.layoutIfNeeded()
        })
        
    }
}
