//
//  BottomView.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreGraphics
import EventKit
import Contacts

protocol BottomViewDelegate: class {
    func bottomView(_ bottomView: BottomView, textViewDidChange textView: TextView)
    func bottomView(_ bottomView: BottomView, didFinishTyping str: String)
    func bottomView(_ bottomView: BottomView, moveToDetailForNewNote: Bool)
    
}

class BottomView: View {
    
    @IBOutlet weak var sendButton: Button!
    @IBOutlet weak var writeButton: Button!
    @IBOutlet weak var textView: GrowingTextView!
    @IBOutlet weak var recommandReminderView: RecommandReminderView!
    @IBOutlet weak var recommandEventView: RecommandEventView!
    @IBOutlet weak var recommandContactView: RecommandContactView!
    @IBOutlet weak var recommandAddressView: RecommandAddressView!
    
    
    
    var recommandData: Recommandable? {
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
            if newValue is EKReminder {
                recommandReminderView.data = newValue
                recommandEventView.data = nil
                recommandContactView.data = nil
                recommandAddressView.data = nil
            } else if newValue is EKEvent {
                recommandEventView.data = newValue
                recommandReminderView.data = nil
                recommandContactView.data = nil
                recommandAddressView.data = nil
            } else if let contact = newValue as? CNContact, contact.postalAddresses.count != 0 {
                recommandAddressView.data = newValue
                recommandContactView.data = nil
                recommandEventView.data = nil
                recommandReminderView.data = nil
            } else if let contact = newValue as? CNContact,
                contact.postalAddresses.count == 0 {
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
        }
    }
    
    
    weak var masterViewController: BottomViewDelegate?
    
    @IBOutlet weak var bottomViewBottomAnchor: LayoutConstraint!
    
    /** 유저 인터렉션에 따라 자연스럽게 바텀뷰가 내려가게 하기 위한 옵저빙 토큰 */
    internal var keyboardToken: NSKeyValueObservation?
    internal var keyboardHeight: CGFloat?

}
