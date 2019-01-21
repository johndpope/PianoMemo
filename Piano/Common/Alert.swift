//
//  Alert.swift
//  Piano
//
//  Created by Kevin Kim on 15/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

struct Alert {

    static func warning(from vc: ViewController, title: String, message: String, afterCancel: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            let alert = AlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = AlertAction(title: "Done".loc, style: .cancel, handler: { (_) in
                afterCancel?()
            })
            alert.addAction(okAction)
            vc.present(alert, animated: true)
        }
    }

    static func deleteAll(from vc: ViewController, afterCancel: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            let alert = AlertController(title: "Permanently Delete".loc, message: "Remove All?".loc, preferredStyle: .alert)
            let okAction = AlertAction(title: "Delete".loc, style: .default, handler: { (_) in
                afterCancel?()
            })
            let cancelAction = AlertAction(title: "Cancel".loc, style: .cancel)

            alert.addAction(okAction)
            alert.addAction(cancelAction)
            vc.present(alert, animated: true)
        }
    }

    static func reminder(from vc: ViewController) {
        DispatchQueue.main.async {
            let alert = AlertController(title: "Allow Access".loc, message: "Please allow to access reminders🙏".loc, preferredStyle: .alert)
            let cancelAction = AlertAction(title: "Cancel".loc, style: .cancel)
            let settingAction = AlertAction(title: "Move to Settings".loc, style: .default) { _ in
                Application.shared.open(URL(string: Application.openSettingsURLString)!)
            }
            alert.addAction(cancelAction)
            alert.addAction(settingAction)
            vc.present(alert, animated: true)
        }
    }

    static func location(from vc: ViewController) {
        DispatchQueue.main.async {
            let alert = AlertController(title: "Allow Access".loc, message: "Please allow to access location🙏".loc, preferredStyle: .alert)
            let cancelAction = AlertAction(title: "Cancel".loc, style: .cancel)
            let settingAction = AlertAction(title: "Move to Settings".loc, style: .default) { _ in
                Application.shared.open(URL(string: Application.openSettingsURLString)!)
            }
            alert.addAction(cancelAction)
            alert.addAction(settingAction)
            vc.present(alert, animated: true)
        }
    }

    static func event(from vc: ViewController) {
        DispatchQueue.main.async {
            let alert = AlertController(title: "Allow Access".loc, message: "Please allow to access calendar🙏".loc, preferredStyle: .alert)
            let cancelAction = AlertAction(title: "Cancel".loc, style: .cancel)
            let settingAction = AlertAction(title: "Move to Settings".loc, style: .default) { _ in
                Application.shared.open(URL(string: Application.openSettingsURLString)!)
            }
            alert.addAction(cancelAction)
            alert.addAction(settingAction)
            vc.present(alert, animated: true)
        }
    }

    static func photo(from vc: ViewController) {
        DispatchQueue.main.async {
            let alert = AlertController(title: "Allow Access".loc, message: "Please allow to access photos🙏".loc, preferredStyle: .alert)
            let cancelAction = AlertAction(title: "Cancel".loc, style: .cancel)
            let settingAction = AlertAction(title: "Move to Settings".loc, style: .default) { _ in
                Application.shared.open(URL(string: Application.openSettingsURLString)!)
            }
            alert.addAction(cancelAction)
            alert.addAction(settingAction)
            vc.present(alert, animated: true)
        }
    }

    static func contact(from vc: ViewController) {
        DispatchQueue.main.async {
            let alert = AlertController(title: "Allow Access".loc, message: "Please allow to access contacts🙏".loc, preferredStyle: .alert)
            let cancelAction = AlertAction(title: "Cancel".loc, style: .cancel)
            let settingAction = AlertAction(title: "Move to Settings".loc, style: .default) { _ in
                Application.shared.open(URL(string: Application.openSettingsURLString)!)
            }
            alert.addAction(cancelAction)
            alert.addAction(settingAction)
            vc.present(alert, animated: true)
        }
    }

}
