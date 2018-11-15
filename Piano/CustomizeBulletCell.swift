//
//  CustomizeBulletCell.swift
//  Piano
//
//  Created by Kevin Kim on 14/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class CustomizeBulletCell: UITableViewCell {
    enum EditingState {
        case shortcut
        case checkOff
        case checkOn
    }
    
    weak var vc: CustomizeBulletTableViewController?
    var state: EditingState = .shortcut
    var userDefineForm: UserDefineForm? {
        didSet {
            guard let userDefineForm = userDefineForm else { return }
            shortcutButton.setTitle(userDefineForm.keyOff, for: .normal)
            checkOffButton.setTitle(userDefineForm.valueOff, for: .normal)
            checkOnButton.setTitle(userDefineForm.valueOn, for: .normal)
        }
    }
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var shortcutButton: UIButton!
    @IBOutlet weak var checkOffButton: UIButton!
    @IBOutlet weak var checkOnButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func tapShortcut(_ sender: UIButton) {
        setBackgroundColor(sender: sender)
        textField.becomeFirstResponder()
        state = .shortcut
    }
    @IBAction func tapCheckOff(_ sender: UIButton) {
        setBackgroundColor(sender: sender)
        textField.becomeFirstResponder()
        state = .checkOff
    }
    @IBAction func tapCheckOn(_ sender: UIButton) {
        setBackgroundColor(sender: sender)
        textField.becomeFirstResponder()
        state = .checkOn
    }
    
    private func setBackgroundColor(sender: UIButton) {
        let selectedColor = Color(red: 153/255, green: 199/255, blue: 255/255, alpha: 0.5)
        shortcutButton.backgroundColor = shortcutButton != sender ? .clear : selectedColor
        checkOnButton.backgroundColor = checkOnButton != sender ? .clear : selectedColor
        checkOffButton.backgroundColor = checkOffButton != sender ? .clear : selectedColor
    }
    
}

extension CustomizeBulletCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        shortcutButton.backgroundColor = .clear
        checkOnButton.backgroundColor = .clear
        checkOffButton.backgroundColor = .clear
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch state {
        case .shortcut:
            if PianoBullet.keyOnList.contains(string) || string.containsEmoji || string.contains("#") {
                //경고 노티 띄우기
                (vc?.navigationController as? TransParentNavigationController)?.show(message: "You can't use this key for shortcut.".loc, color: Color.redNoti)
                
            } else {
                shortcutButton.setTitle(string, for: .normal)
                
                //TODO: 유저디폴트에 반영하기
                guard let indexPath = vc?.tableView.indexPath(for: self) else { return false }
                var userDefineForms = PianoBullet.userDefineForms
                userDefineForms[indexPath.row].keyOff = string
                PianoBullet.userDefineForms = userDefineForms
                
            }
        case .checkOn:
            let count = PianoBullet.userDefineForms.filter {
                return string == $0.valueOff || string == $0.valueOn
                }.count
            
            if !string.containsEmoji || count != 0 {
                //경고 노티 띄우기
                (vc?.navigationController as? TransParentNavigationController)?.show(message: "You can't use same emoji.".loc, color: Color.redNoti)
            } else {
                checkOnButton.setTitle(string, for: .normal)
                
                //TODO: 유저디폴트에 반영하기
                guard let indexPath = vc?.tableView.indexPath(for: self) else { return false }
                var userDefineForms = PianoBullet.userDefineForms
                userDefineForms[indexPath.row].valueOn = string
                PianoBullet.userDefineForms = userDefineForms
            }
            
        case .checkOff:
            let count = PianoBullet.userDefineForms.filter {
                return string == $0.valueOff || string == $0.valueOn
                }.count
            
            if !string.containsEmoji || count != 0 {
                //경고창 띄우기
                (vc?.navigationController as? TransParentNavigationController)?.show(message: "You can't use text or same emoji.".loc, color: Color.redNoti)
            } else {
                checkOffButton.setTitle(string, for: .normal)
                //TODO: 유저디폴트에 반영하기
                guard let indexPath = vc?.tableView.indexPath(for: self) else { return false }
                var userDefineForms = PianoBullet.userDefineForms
                userDefineForms[indexPath.row].valueOff = string
                PianoBullet.userDefineForms = userDefineForms
            }
            
            
        }
        
        
        return false
    }
}
