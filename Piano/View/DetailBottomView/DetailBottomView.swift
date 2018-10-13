//
//  DetailBottomView.swift
//  Piano
//
//  Created by Kevin Kim on 04/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import EventKit
import Contacts

class DetailBottomView: UIStackView {
    @IBOutlet weak var recommandContactView: RecommandContactView!
    @IBOutlet weak var recommandEventView: RecommandEventView!
    @IBOutlet weak var recommandAddressView: RecommandAddressView!
    @IBOutlet weak var recommandReminderView: RecommandReminderView!
    private var kbHeight: CGFloat = 0
    
    private weak var textView: TextView?
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        registerAllNotifications()
    }
    
    deinit {
        unRegisterAllNotifications()
    }
    
    
    internal func setup(viewController: ViewController, textView: TextView) {
        self.textView = textView
        recommandReminderView.setup(viewController: viewController, textView: textView)
        recommandContactView.setup(viewController: viewController, textView: textView)
        recommandAddressView.setup(viewController: viewController, textView: textView)
        recommandEventView.setup(viewController: viewController, textView: textView)
    }

    internal var recommandData: Recommandable? {
        get {
            if let data = recommandReminderView.data {
                return data
            } else if let data = recommandEventView.data {
                return data
            } else if let data = recommandContactView.data {
                return data
            } else if let data = recommandAddressView.data {
                return data
            } else {
                return nil
            }
        } set {
            var contentInsetBottom = kbHeight
            if newValue is EKReminder {
                contentInsetBottom += 86
                recommandReminderView.data = newValue
                recommandEventView.data = nil
                recommandContactView.data = nil
                recommandAddressView.data = nil
            } else if newValue is EKEvent {
                contentInsetBottom += 105
                recommandEventView.data = newValue
                recommandReminderView.data = nil
                recommandContactView.data = nil
                recommandAddressView.data = nil
            } else if let contact = newValue as? CNContact, contact.postalAddresses.count != 0 {
                contentInsetBottom += 88
                recommandAddressView.data = newValue
                recommandContactView.data = nil
                recommandEventView.data = nil
                recommandReminderView.data = nil
            } else if let contact = newValue as? CNContact,
                contact.postalAddresses.count == 0 {
                contentInsetBottom += 109
                recommandContactView.data = newValue
                recommandAddressView.data = nil
                recommandReminderView.data = nil
                recommandEventView.data = nil
            } else {
                recommandContactView.data = nil
                recommandReminderView.data = nil
                recommandEventView.data = nil
                recommandAddressView.data = nil
            }
//            DispatchQueue.main.async { [weak self] in
//                self?.textView?.setInset(contentInsetBottom: contentInsetBottom)
//            }
        }
    }

}

extension DetailBottomView {
    internal func registerAllNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    internal func unRegisterAllNotifications(){
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        self.kbHeight = 0
    }
    
    @objc func keyboardDidHide(_ notification: Notification) {
        recommandData = nil
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            let kbHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height
            else { return }
        self.kbHeight = kbHeight
    }
}
