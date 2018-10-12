//
//  AccessEventViewController.swift
//  Piano
//
//  Created by Kevin Kim on 14/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import EventKit

class AccessEventViewController: UIViewController {

    let store = EKEventStore()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func access(_ sender: Any) {
        requestAccess()
    }
    
    @IBAction func pass(_ sender: Any) {
        DispatchQueue.main.async { [weak self] in
            self?.performSegue(withIdentifier: AccessReminderViewController.identifier, sender: nil)
        }
    }
    
    private func requestAccess() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined:
            store.requestAccess(to: .event) { [weak self] (status, error) in
                guard let `self` = self else { return }
                switch status {
                case true: self.pass(status)
                case false: Alert.event(from: self)
                }
            }
            
        case .authorized: self.pass(true)
        case .restricted, .denied: Alert.event(from: self)
        }
    }
    
}
