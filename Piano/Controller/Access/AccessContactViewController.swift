//
//  AccessContactViewController.swift
//  Piano
//
//  Created by Kevin Kim on 14/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import Contacts

class AccessContactViewController: UIViewController {

    let store = CNContactStore()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func access(_ sender: Any) {
        requestAccess()
    }
    
    @IBAction func pass(_ sender: Any) {
        DispatchQueue.main.async { [weak self] in
            self?.performSegue(withIdentifier: AccessPhotoViewController.identifier, sender: nil)
        }
    }
    
    private func requestAccess() {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .notDetermined:
            store.requestAccess(for: .contacts) { [weak self] (status, error) in
                guard let `self` = self else { return }
                switch status {
                case true: self.pass(status)
                case false: Alert.contact(from: self)
                }
            }
        case .authorized: self.pass(true)
        case .restricted, .denied: Alert.contact(from: self)
        }
    }
    

}
