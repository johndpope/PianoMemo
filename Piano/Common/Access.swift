//
//  Access.swift
//  Piano
//
//  Created by Kevin Kim on 16/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import EventKit
import Contacts
import Photos

struct Access {
    static func eventRequest(from vc: ViewController, success: (() -> Void)?) {
        let store = EKEventStore()

        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined:
            store.requestAccess(to: .event) { [weak vc] (status, _) in
                guard let vc = vc else { return }
                switch status {
                case true: success?()
                case false: Alert.event(from: vc)
                }
            }

        case .authorized:  success?()
        case .restricted, .denied: Alert.event(from: vc)
        }
    }

    static func contactRequest(from vc: ViewController, success: (() -> Void)?) {
        let store = CNContactStore()
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .notDetermined:
            store.requestAccess(for: .contacts) { [weak vc] (status, _) in
                guard let vc = vc else { return }
                switch status {
                case true:  success?()
                case false: Alert.contact(from: vc)
                }
            }
        case .authorized:  success?()
        case .restricted, .denied: Alert.contact(from: vc)
        }
    }

    static func reminderRequest(from vc: ViewController, success: (() -> Void)?) {
        let store = EKEventStore()
        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .notDetermined:
            store.requestAccess(to: .reminder) { [weak vc] (status, _) in
                guard let vc = vc else { return }
                switch status {
                case true:  success?()
                case false: Alert.reminder(from: vc)
                }
            }

        case .authorized:  success?()
        case .restricted, .denied: Alert.reminder(from: vc)
        }
    }

    static func photoRequest(from vc: ViewController, success: (() -> Void)?) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak vc] (status) in
                guard let vc = vc else { return }
                switch status {
                case .authorized:
                    success?()
                default:
                    Alert.photo(from: vc)
                }
            }
        case .authorized: success?()
        default: Alert.photo(from: vc)
        }
    }

    static func locationRequest(from vc: ViewController & CLLocationManagerDelegate, manager: CLLocationManager, success: (() -> Void)?) {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            // Disable location features
            Alert.location(from: vc)
        case .authorizedWhenInUse:
            // Enable basic location features
            success?()
        case .authorizedAlways:
            // Enable any of your app's location features
            success?()
        }
    }

}
