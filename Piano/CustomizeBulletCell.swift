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
            guard let userDefineForm = userDefineForm else {
                lockButton.isHidden = false
                return
            }
            
            lockButton.isHidden = true
            shortcutButton.setTitle(userDefineForm.shortcut, for: .normal)
            checkOffButton.setTitle(userDefineForm.valueOff, for: .normal)
            checkOnButton.setTitle(userDefineForm.valueOn, for: .normal)
        }
    }
    
    @IBOutlet weak var emojiTextField: EmojiTextField!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var shortcutButton: UIButton!
    @IBOutlet weak var checkOffButton: UIButton!
    @IBOutlet weak var checkOnButton: UIButton!
    @IBOutlet weak var lockButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func tapShortcut(_ sender: UIButton) {
        DispatchQueue.main.async { [weak self] in
            self?.setBackgroundColor(sender: sender)
        }
        setEmojiKeyboard()
        textField.becomeFirstResponder()
        state = .shortcut
    }
    @IBAction func tapCheckOff(_ sender: UIButton) {
        DispatchQueue.main.async { [weak self] in
            self?.setBackgroundColor(sender: sender)
        }
        setEmojiKeyboard()
        emojiTextField.becomeFirstResponder()
        state = .checkOff
    }
    @IBAction func tapCheckOn(_ sender: UIButton) {
        DispatchQueue.main.async { [weak self] in
            self?.setBackgroundColor(sender: sender)
        }
        setEmojiKeyboard()
        emojiTextField.becomeFirstResponder()
        state = .checkOn
    }
    
    @IBAction func tapLock(_ sender: UIButton) {
        
    }
    
    private func setEmojiKeyboard(){
        let emojiKeyboard = UITextInputMode.activeInputModes.filter { $0.primaryLanguage == "emoji" }
        
        if emojiKeyboard.count == 0 {
            let emptyInputView = self.createSubviewIfNeeded(EmptyInputView.self)
            emptyInputView?.completionHandler = { [weak self] in
                self?.emojiTextField.inputView = nil
                self?.emojiTextField.resignFirstResponder()
            }
            emojiTextField.inputView = emptyInputView
        } 
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
            let existShortcut = PianoBullet.userDefineForms.contains {
                return $0.shortcut == string || $0.keyOff == string || $0.keyOn == string
            }
            
            if existShortcut || string.containsEmoji || string.contains("#") {
                //경고 노티 띄우기
                (vc?.navigationController as? TransParentNavigationController)?.show(message: "단축키로 이 값을 사용할 수 없어요.".loc, color: Color.redNoti)
                
            } else {
                shortcutButton.setTitle(string, for: .normal)
                
                //TODO: 유저디폴트에 반영하기
                guard let indexPath = vc?.tableView.indexPath(for: self) else { return false }
                var userDefineForms = PianoBullet.userDefineForms
                userDefineForms[indexPath.row].shortcut = string
                PianoBullet.userDefineForms = userDefineForms
                
            }
        case .checkOn:
            let existCheckOn = PianoBullet.userDefineForms.contains {
                return string == $0.valueOff || string == $0.valueOn
            }
            
            if !string.containsEmoji || existCheckOn {
                //경고 노티 띄우기
                (vc?.navigationController as? TransParentNavigationController)?.show(message: "이모지를 중복해 사용할 수 없어요.".loc, color: Color.redNoti)
            } else {
                checkOnButton.setTitle(string, for: .normal)
                
                //TODO: 유저디폴트에 반영하기
                guard let indexPath = vc?.tableView.indexPath(for: self) else { return false }
                var userDefineForms = PianoBullet.userDefineForms
                userDefineForms[indexPath.row].valueOn = string
                PianoBullet.userDefineForms = userDefineForms
            }
            
        case .checkOff:
            let existCheckOff = PianoBullet.userDefineForms.contains {
                return string == $0.valueOff || string == $0.valueOn
            }

            if !string.containsEmoji || existCheckOff {
                //경고창 띄우기
                (vc?.navigationController as? TransParentNavigationController)?.show(message: "이 글자 혹은 이모지를 사용할 수 없어요.".loc, color: Color.redNoti)
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
