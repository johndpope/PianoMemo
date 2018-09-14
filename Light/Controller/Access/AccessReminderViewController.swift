//
//  AccessReminderViewController.swift
//  Piano
//
//  Created by Kevin Kim on 14/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import EventKit

class AccessReminderViewController: UIViewController {

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
            self?.performSegue(withIdentifier: AccessContactViewController.identifier, sender: nil)
        }
    }
    
    private func requestAccess() {
        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .notDetermined:
            store.requestAccess(to: .reminder) { [weak self] (status, error) in
                guard let `self` = self else { return }
                switch status {
                case true: self.pass(status)
                case false: self.alert()
                }
            }
            
        case .authorized: self.pass(true)
        case .restricted, .denied: alert()
        }
    }
    
    private func alert() {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: nil, message: "permission_reminder".loc, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "cancel".loc, style: .cancel)
            let settingAction = UIAlertAction(title: "setting".loc, style: .default) { _ in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
            alert.addAction(cancelAction)
            alert.addAction(settingAction)
            self?.present(alert, animated: true)
        }
    }
    
}
