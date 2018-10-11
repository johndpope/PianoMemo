//
//  TempFile.swift
//  Piano
//
//  Created by Kevin Kim on 11/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

//internal func setInputViewForNil(){
//    guard let textView = textView else { return }
//    textView.inputView = nil
//    textView.reloadInputViews()
//}
//
//internal func setInputViewForReminder() {
//    guard let vc = viewController,
//        let textView = textView,
//        let textInputView = vc.textInputView else { return }
//    
//    if !textView.isFirstResponder {
//        textView.becomeFirstResponder()
//    }
//    
//    CATransaction.setCompletionBlock { [weak self] in
//        guard let self = self else { return }
//        textInputView.frame.size.height = self.kbHeight
//        textView.inputView = textInputView
//        textView.reloadInputViews()
//        textInputView.dataType = .reminder
//    }
//}
//
//internal func setContactPicker() {
//    guard let vc = viewController,
//        let textView = textView else { return }
//    
//    if textView.inputView != nil {
//        textView.inputView = nil
//        textView.reloadInputViews()
//    }
//    
//    let contactPickerVC = CNContactPickerViewController()
//    contactPickerVC.delegate = self
//    selectedRange = textView.selectedRange
//    vc.present(contactPickerVC, animated: true, completion: nil)
//}
//
//internal func setCurrentTime() {
//    guard let textView = textView else { return }
//    
//    if textView.inputView != nil {
//        textView.inputView = nil
//        textView.reloadInputViews()
//    }
//    
//    textView.insertText(DateFormatter.longSharedInstance.string(from: Date()))
//}
