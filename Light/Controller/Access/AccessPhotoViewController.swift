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

        // Do any additional setup after loading the view.
    }
    

    @IBAction func access(_ sender: Any) {
        requestPhotoAccess()
    }
    
    @IBAction func pass(_ sender: Any) {
        dismiss(animated: true) {
            UserDefaults.standard.set(true, forKey: existUserKey)
        }
        dismiss(animated: true, completion: nil)
    }
    
    private func requestPhotoAccess() {
        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] (status) in
                guard let `self` = self else { return }
                switch status {
                case .authorized:
                    self.requestLocationAccess()
                default:
                    self.alertPhoto()
                }
            }
        case .authorized: requestLocationAccess()
        default: alertPhoto()
        }
    }
    
    private func alertPhoto() {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: nil, message: "permission_photo".loc, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "cancel".loc, style: .cancel)
            let settingAction = UIAlertAction(title: "setting".loc, style: .default) { _ in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
            alert.addAction(cancelAction)
            alert.addAction(settingAction)
            self?.present(alert, animated: true)
        }
    }
    
    private func alertLocation() {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: nil, message: "permission_location".loc, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "cancel".loc, style: .cancel)
            let settingAction = UIAlertAction(title: "setting".loc, style: .default) { _ in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
            alert.addAction(cancelAction)
            alert.addAction(settingAction)
            self?.present(alert, animated: true)
        }
    }
    
    func requestLocationAccess() {
        locationManager.delegate = self
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            // Request when-in-use authorization initially
            locationManager.requestWhenInUseAuthorization()
            break
            
        case .restricted, .denied:
            // Disable location features
            alertLocation()
            break
            
        case .authorizedWhenInUse:
            // Enable basic location features
            pass(true)
            break
            
        case .authorizedAlways:
            // Enable any of your app's location features
            pass(true)
            break
        }
    }
}

extension AccessPhotoViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted, .denied:
            // Disable your app's location features
            alertLocation()
            break
            
        case .authorizedWhenInUse:
            pass(true)
            break
            
        case .authorizedAlways:
            pass(true)
            break
            
        case .notDetermined:
            requestLocationAccess()
            break
        }
    }
}
