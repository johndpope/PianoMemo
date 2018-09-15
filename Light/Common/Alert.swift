//
//  Alert.swift
//  Piano
//
//  Created by Kevin Kim on 15/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

struct Alert {
    static func reminder(from vc: ViewController) {
        DispatchQueue.main.async {
            let alert = AlertController(title: nil, message: "permission_reminder".loc, preferredStyle: .alert)
            let cancelAction = AlertAction(title: "cancel".loc, style: .cancel)
            let settingAction = AlertAction(title: "setting".loc, style: .default) { _ in
                Application.shared.open(URL(string: Application.openSettingsURLString)!)
            }
            alert.addAction(cancelAction)
            alert.addAction(settingAction)
            
            vc.present(alert, animated: true)
        }
    }
    
    static func location(from vc: ViewController) {
        DispatchQueue.main.async {
            let alert = AlertController(title: nil, message: "permission_location".loc, preferredStyle: .alert)
            let cancelAction = AlertAction(title: "cancel".loc, style: .cancel)
            let settingAction = AlertAction(title: "setting".loc, style: .default) { _ in
                Application.shared.open(URL(string: Application.openSettingsURLString)!)
            }
            alert.addAction(cancelAction)
            alert.addAction(settingAction)
            vc.present(alert, animated: true)
        }
    }
    
    static func event(from vc: ViewController) {
        DispatchQueue.main.async {
            let alert = AlertController(title: nil, message: "permission_event".loc, preferredStyle: .alert)
            let cancelAction = AlertAction(title: "cancel".loc, style: .cancel)
            let settingAction = AlertAction(title: "setting".loc, style: .default) { _ in
                Application.shared.open(URL(string: Application.openSettingsURLString)!)
            }
            alert.addAction(cancelAction)
            alert.addAction(settingAction)
            vc.present(alert, animated: true)
        }
    }
    
    static func photo(from vc: ViewController) {
        DispatchQueue.main.async {
            let alert = AlertController(title: nil, message: "permission_photo".loc, preferredStyle: .alert)
            let cancelAction = AlertAction(title: "cancel".loc, style: .cancel)
            let settingAction = AlertAction(title: "setting".loc, style: .default) { _ in
                Application.shared.open(URL(string: Application.openSettingsURLString)!)
            }
            alert.addAction(cancelAction)
            alert.addAction(settingAction)
            vc.present(alert, animated: true)
        }
    }
    
    static func contact(from vc: ViewController) {
        DispatchQueue.main.async {
            let alert = AlertController(title: nil, message: "permission_contact".loc, preferredStyle: .alert)
            let cancelAction = AlertAction(title: "cancel".loc, style: .cancel)
            let settingAction = AlertAction(title: "setting".loc, style: .default) { _ in
                Application.shared.open(URL(string: Application.openSettingsURLString)!)
            }
            alert.addAction(cancelAction)
            alert.addAction(settingAction)
            vc.present(alert, animated: true)
        }
    }
    
}
