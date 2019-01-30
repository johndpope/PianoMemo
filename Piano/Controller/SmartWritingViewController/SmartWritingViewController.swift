//
//  LighteningViewController.swift
//  Piano
//
//  Created by Kevin Kim on 08/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit
import CoreLocation
import Contacts
import EventKit

class SmartWritingViewController: UIViewController {
    weak var noteHandler: NoteHandlable?
    var noteCollectionState: NoteCollectionViewController.NoteCollectionState = .all

    
    @IBOutlet weak var bottomViewBottomAnchor: NSLayoutConstraint!
    @IBOutlet weak var textView: GrowingTextView!
    let locationManager = CLLocationManager()
    @IBOutlet weak var eraseBtn: UIButton!
    @IBOutlet weak var sendBtn: UIButton!
    @IBOutlet weak var timeBtn: UIButton!
    
    @IBOutlet weak var recommandReminderView: RecommandReminderView!
    @IBOutlet weak var recommandEventView: RecommandEventView!
    @IBOutlet weak var recommandContactView: RecommandContactView!
    @IBOutlet weak var recommandAddressView: RecommandAddressView!
    @IBOutlet weak var suggestionGuideButton: UIButton!
    @IBOutlet weak var suggestionGuideView: SuggestionGuideView!

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
                setHiddenGuideViews(isHidden: true)
            } else if newValue is EKEvent {
                recommandEventView.data = newValue
                recommandReminderView.data = nil
                recommandContactView.data = nil
                recommandAddressView.data = nil
                setHiddenGuideViews(isHidden: true)
            } else if let contact = newValue as? CNContact, contact.postalAddresses.count != 0 {
                recommandAddressView.data = newValue
                recommandContactView.data = nil
                recommandEventView.data = nil
                recommandReminderView.data = nil
                setHiddenGuideViews(isHidden: true)
            } else if let contact = newValue as? CNContact,
                contact.postalAddresses.count == 0 {
                recommandContactView.data = newValue
                recommandAddressView.data = nil
                recommandReminderView.data = nil
                recommandEventView.data = nil
                setHiddenGuideViews(isHidden: true)
            } else {
                recommandContactView.data = nil
                recommandReminderView.data = nil
                recommandEventView.data = nil
                recommandAddressView.data = nil
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let view = UIView()
        view.backgroundColor = Color.clear
        view.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 100, height: 0.1))
        textView.inputAccessoryView = view

        recommandEventView.setup(viewController: self, textView: textView)
        recommandAddressView.setup(viewController: self, textView: textView)
        recommandContactView.setup(viewController: self, textView: textView)
        recommandReminderView.setup(viewController: self, textView: textView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        registerAllNotification()
        textView.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unRegisterAllNotification()
    }
}
