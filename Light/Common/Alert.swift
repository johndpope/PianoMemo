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
            let okAction = AlertAction(title: "확인".loc, style: .cancel, handler: { (_) in
                afterCancel?()
            })
            alert.addAction(okAction)
            vc.present(alert, animated: true)
        }
    }
    
    static func trash(from vc: ViewController, afterCancel: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            let alert = AlertController(title: "휴지통으로 이동".loc, message: "해당 메모는 휴지통에 보관돼요. 휴지통은 설정에 있어요.".loc, preferredStyle: .alert)
            let okAction = AlertAction(title: "확인".loc, style: .cancel, handler: { (_) in
                afterCancel?()
            })
            alert.addAction(okAction)
            vc.present(alert, animated: true)
        }
    }
    
    static func deleteAll(from vc: ViewController, afterCancel: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            let alert = AlertController(title: "영구 삭제".loc, message: "휴지통에 있는 메모들을 영구 삭제 할까요?".loc, preferredStyle: .alert)
            let okAction = AlertAction(title: "삭제".loc, style: .default, handler: { (_) in
                afterCancel?()
            })
            let cancelAction = AlertAction(title: "취소".loc, style: .cancel)
            
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            vc.present(alert, animated: true)
        }
    }
    
    static func restoreAll(from vc: ViewController, afterCancel: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            let alert = AlertController(title: "전체 복원".loc, message: "휴지통에 있는 메모들을 전체 복구 할까요?".loc, preferredStyle: .alert)
            let okAction = AlertAction(title: "복구".loc, style: .default, handler: { (_) in
                afterCancel?()
            })
            let cancelAction = AlertAction(title: "취소".loc, style: .cancel)
            
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            vc.present(alert, animated: true)
        }
    }
    
    static func reminder(from vc: ViewController) {
        DispatchQueue.main.async {
            let alert = AlertController(title: nil, message: "permission_reminder".loc, preferredStyle: .alert)
            let cancelAction = AlertAction(title: "cancel".loc, style: .cancel)
            let settingAction = AlertAction(title: "설정으로 이동".loc, style: .default) { _ in
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
            let settingAction = AlertAction(title: "설정으로 이동".loc, style: .default) { _ in
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
            let settingAction = AlertAction(title: "설정으로 이동".loc, style: .default) { _ in
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
            let settingAction = AlertAction(title: "설정으로 이동".loc, style: .default) { _ in
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
            let settingAction = AlertAction(title: "설정으로 이동".loc, style: .default) { _ in
                Application.shared.open(URL(string: Application.openSettingsURLString)!)
            }
            alert.addAction(cancelAction)
            alert.addAction(settingAction)
            vc.present(alert, animated: true)
        }
    }
    
}
