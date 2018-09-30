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
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeStatusBarOrientation(_:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    internal func unRegisterAllNotifications(){
        NotificationCenter.default.removeObserver(self)
    }
    
    internal func hideKeyboard() {
        //TODO: 화면 회전하면 일부로 키보드를 꺼서 키보드 높이에 input뷰가 적응하게 만든다. 그리고 플러스 버튼을 리셋시키기 위한 코드
        //키보드가 올라와 있으면서 인풋뷰가 nil이 아닐때가 문제가 있는것이므로 그럴 때에는 nil시켜주고 플러스 버튼을 꺼준다.
        
        if textView.isFirstResponder {
            textView.resignFirstResponder()
        }
        if plusButton.isSelected {
            plus(plusButton)
        }
        
        plusButton.isHidden = true
    }
    
    @objc func didChangeStatusBarOrientation(_ notification: Notification) {
        hideKeyboard()
        textInputView.collectionView.collectionViewLayout.invalidateLayout()
        
        guard !self.textView.isSelectable,
            let pianoControl = self.textView.pianoControl,
            let pianoView = self.pianoView else { return }
        self.connect(pianoView: pianoView, pianoControl: pianoControl, textView: self.textView)
        pianoControl.attach(on: self.textView)
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        
        setNavigationItems(state: state)
        textView.contentInset.bottom = completionToolbar.bounds.height
        textView.scrollIndicatorInsets.bottom = completionToolbar.bounds.height
        keyboardToken?.invalidate()
        keyboardToken = nil
    }
    
    @objc func keyboardDidHide(_ notification: Notification) {
        hideKeyboard()
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        plusButton.isHidden = false
        
        guard let userInfo = notification.userInfo,
            let kbHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height,
            let _ = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
            else { return }
        
        textView.contentInset.bottom = kbHeight
        textView.scrollIndicatorInsets.bottom = kbHeight
        
        setNavigationItems(state: .typing)
        textAccessoryBottomAnchor.constant = kbHeight
        self.kbHeight = kbHeight
        view.layoutIfNeeded()
        
        keyboardToken = UIApplication.shared.windows[1].subviews.first?.subviews.first?.layer.observe(\.position, changeHandler: { [weak self](layer, change) in
            guard let `self` = self else { return }
            
            self.textAccessoryBottomAnchor.constant = max(self.view.bounds.height - layer.frame.origin.y, 0)
            self.view.layoutIfNeeded()
        })
    }
}
