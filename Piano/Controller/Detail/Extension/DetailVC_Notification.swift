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
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeDidChangeNotification(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeStatusBarOrientation(_:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pasteboardChanged), name: UIPasteboard.changedNotification, object: nil)
    }
    
    @objc func pasteboardChanged() {
        let str = UIPasteboard.general.string ?? ""
        clipboardBarButton.image = str.count != 0 ? #imageLiteral(resourceName: "yesclipboardToolbar") : #imageLiteral(resourceName: "noclipboardToolbar")
    }
    
    internal func unRegisterAllNotifications(){
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func contentSizeDidChangeNotification(_ notification: Notification) {
        guard let note = note else { return }
        textView.setup(note: note) { _ in }
    }
    
    @objc func didChangeStatusBarOrientation(_ notification: Notification) {
        if let pianoControl = textView.pianoControl,
            let pianoView = pianoView,
            !textView.isSelectable {
            connect(pianoView: pianoView, pianoControl: pianoControl, textView: textView)
            pianoControl.attach(on: textView)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: nil) {[unowned self] (_) in
            guard let textView = self.textView else { return }
            if let pianoControl = textView.pianoControl,
                let pianoView = self.pianoView,
                !textView.isSelectable {
                self.connect(pianoView: pianoView, pianoControl: pianoControl, textView: textView)
                pianoControl.attach(on: textView)
            }
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        textView.contentInset.bottom = 100
        textView.scrollIndicatorInsets.bottom = 100
        view.layoutIfNeeded()
        setNavigationItems(state: state)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            let kbHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height,
            let _ = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
            else { return }
        let height = kbHeight
        textView.contentInset.bottom = height
        textView.scrollIndicatorInsets.bottom = height

        setNavigationItems(state: .typing)
        view.layoutIfNeeded()
    }
}
