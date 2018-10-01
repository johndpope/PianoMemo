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
    
    private func hideKeyboard() {
        //TODO: 화면 회전하면 일부로 키보드를 꺼서 키보드 높이에 input뷰가 적응하게 만든다. 그리고 플러스 버튼을 리셋시키기 위한 코드
        
        bottomView.textView.inputView = nil
        bottomView.textView.reloadInputViews()
        bottomView.textView.becomeFirstResponder()

        textAccessoryVC?.collectionView.indexPathsForSelectedItems?.forEach {
            textAccessoryVC?.collectionView.deselectItem(at: $0, animated: false)
        }
    }
    
    @objc func didChangeStatusBarOrientation(_ notification: Notification) {
        hideKeyboard()
        collectionView.collectionViewLayout.invalidateLayout()
        textInputView.collectionView.collectionViewLayout.invalidateLayout()
        textAccessoryVC?.collectionView.collectionViewLayout.invalidateLayout()
        bottomView.textView.setInset()
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        bottomView.keyboardToken?.invalidate()
        bottomView.keyboardToken = nil
        collectionView.contentInset.bottom = bottomView.bounds.height
        collectionView.scrollIndicatorInsets.bottom = bottomView.bounds.height
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            let kbHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height
            else { return }
        
        bottomView.keyboardHeight = kbHeight
        bottomView.bottomViewBottomAnchor.constant = kbHeight
        collectionView.contentInset.bottom = kbHeight// + bottomView.bounds.height
        collectionView.scrollIndicatorInsets.bottom = kbHeight// + bottomView.bounds.height
        view.layoutIfNeeded()
        self.kbHeight = kbHeight
        
        bottomView.keyboardToken = UIApplication.shared.windows[1].subviews.first?.subviews.first?.layer.observe(\.position, changeHandler: { [weak self](layer, change) in
            guard let `self` = self else { return }
            
            self.bottomView.bottomViewBottomAnchor.constant = max(self.view.bounds.height - layer.frame.origin.y, 0)
            self.view.layoutIfNeeded()
        })
        
    }
}
