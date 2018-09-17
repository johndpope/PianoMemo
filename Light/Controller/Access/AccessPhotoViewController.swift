//
//  AccessPhotoViewController.swift
//  Piano
//
//  Created by Kevin Kim on 14/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import Photos

class AccessPhotoViewController: UIViewController {

    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self

    }
    

    @IBAction func access(_ sender: Any) {
        Access.photoRequest(from: self) { [weak self] in
            guard let `self` = self else { return }
            Access.locationRequest(from: self, manager: self.locationManager, success: {
                self.pass(true)
            })
        }
        
    }
    
    @IBAction func pass(_ sender: Any) {
        dismiss(animated: true) {
            UserDefaults.standard.set(true, forKey: UserDefaultsKey.isExistingUserKey)
        }
        dismiss(animated: true, completion: nil)
    }
}

extension AccessPhotoViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted, .denied:
            Alert.location(from: self)
            break
            
        case .authorizedWhenInUse:
            pass(true)
            break
            
        case .authorizedAlways:
            pass(true)
            break
            
        case .notDetermined:
            Access.locationRequest(from: self, manager: manager) { [weak self] in
                guard let `self` = self else { return }
                self.pass(true)
            }
            break
        }
    }
}
