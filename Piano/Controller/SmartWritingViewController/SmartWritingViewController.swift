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
    var noteCollectionState: NoteCollectionViewController.NoteCollectionState = .all

    @IBOutlet weak var bottomViewBottomAnchor: NSLayoutConstraint!
    @IBOutlet weak var textView: UITextView!
    lazy var locationManager = CLLocationManager()
    @IBOutlet weak var eraseBtn: UIButton!
    @IBOutlet weak var sendBtn: UIButton!
    @IBOutlet weak var currentLocationButton: UIButton!
    @IBOutlet weak var recommandReminderView: RecommandReminderView!
    @IBOutlet weak var recommandEventView: RecommandEventView!
    @IBOutlet weak var recommandContactView: RecommandContactView!
    @IBOutlet weak var recommandAddressView: RecommandAddressView!
    @IBOutlet weak var suggestionGuideButton: UIButton!
    @IBOutlet weak var suggestionGuideView: SuggestionGuideView!

    var recommandData: Recommandable? {
        get {
            return getRecommandData()
        } set {
            setRecommandViews(newValue)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        registerAllNotification()
        textView.becomeFirstResponder()

        if CLLocationManager.hasAuthorized {
            setLocation(to: currentLocationButton)
        }
    }

    deinit {
        unRegisterAllNotification()
    }

}
