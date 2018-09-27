//
//  MainVC_Action.swift
//  Piano
//
//  Created by Kevin Kim on 17/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import ContactsUI

extension MainViewController {
    internal func setDoneBtn(){
        let doneBtn = BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
        doneBtn.tag = 1
        navigationItem.setRightBarButton(doneBtn, animated: false)
    }
    
    internal func setEditBtn(){
        let editBtn = BarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(edit(_:)))
        editBtn.tag = 0
        navigationItem.setRightBarButton(editBtn, animated: false)
    }
    
    internal func setNormalBtn() {
        let normalBtn = BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(normal(_:)))
        navigationItem.setRightBarButton(normalBtn, animated: false)
    }
    
    internal func setTrashBtn() {
        let trashBtn = BarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(trash(_:)))
        trashBtn.isEnabled = false
        navigationItem.setLeftBarButton(trashBtn, animated: false)
    }
    
    internal func setSettingBtn() {
        let settingBtn = BarButtonItem(title: "Setting", style: .plain, target: self, action: #selector(setting(_:)))
        navigationItem.setLeftBarButton(settingBtn, animated: false)
    }
    
    @IBAction func setting(_ sender: Any) {
        performSegue(withIdentifier: SettingTableViewController.identifier, sender: nil)
    }
    
    @IBAction func calendar(_ sender: Any) {
        
        if bottomView.textView.inputView == nil || textInputView.dataType != .event {
            textInputView.frame.size.height = kbHeight
            bottomView.textView.inputView = textInputView
            bottomView.textView.reloadInputViews()
            textInputView.dataType = .event
        }
        
        if !bottomView.textView.isFirstResponder {
            bottomView.textView.becomeFirstResponder()
        }
    }
    
    @IBAction func reminder(_ sender: Any) {
        if bottomView.textView.inputView == nil || textInputView.dataType != .reminder {
            textInputView.frame.size.height = kbHeight
            bottomView.textView.inputView = textInputView
            bottomView.textView.reloadInputViews()
            textInputView.dataType = .reminder
        }
        
        if !bottomView.textView.isFirstResponder {
            bottomView.textView.becomeFirstResponder()
        }
    }
    
    @IBAction func contact(_ sender: Any) {
        if bottomView.textView.inputView != nil {
            bottomView.textView.inputView = nil
            bottomView.textView.reloadInputViews()
        }
        
        let vc = CNContactPickerViewController()
        vc.delegate = self
        selectedRange = bottomView.textView.selectedRange
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func now(_ sender: Any) {
        if bottomView.textView.inputView != nil {
            bottomView.textView.inputView = nil
            bottomView.textView.reloadInputViews()
        }
        
        bottomView.textView.insertText(DateFormatter.longSharedInstance.string(from: Date()) + "\n")
        
        if !bottomView.textView.isFirstResponder {
            bottomView.textView.becomeFirstResponder()
        }
        
    }
    
    @IBAction func plus(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        textAccessoryView.isHidden = !sender.isSelected
        
        if !sender.isSelected {
            bottomView.textView.inputView = nil
            bottomView.textView.reloadInputViews()
        }
    }
    
    @IBAction func done(_ sender: Any) {
        bottomView.textView.resignFirstResponder()
    }
    
    @IBAction func edit(_ sender: Any) {
        collectionView.allowsMultipleSelection = true
        bottomView.isHidden = true
        title = ""
        setNormalBtn()
        setTrashBtn()
    }
    
    @IBAction func normal(_ sender: Any) {
        collectionView.allowsMultipleSelection = false
        bottomView.isHidden = false
        setEditBtn()
        setSettingBtn()
        
        collectionView.indexPathsForSelectedItems?.forEach {
            collectionView.deselectItem(at: $0, animated: false)
        }
    }
    
    @IBAction func trash(_ sender: Any) {
        if !UserDefaults.standard.bool(forKey: UserDefaultsKey.isExperiencedDeleteNote) {
            Alert.trash(from: self) { [weak self] in
                guard let `self` = self else { return }
                
                self.moveSelectedNotesToTrash()
                UserDefaults.standard.set(true, forKey: UserDefaultsKey.isExperiencedDeleteNote)
            }
            return
        }
        
        moveSelectedNotesToTrash()
    }
    
    private func moveSelectedNotesToTrash() {
        
        guard let indexPathsForSelectedItems = collectionView.indexPathsForSelectedItems?.sorted(by: { $0.item > $1.item }) else { return }
        navigationItem.leftBarButtonItem?.isEnabled = false
        
        backgroundContext.perform { [weak self] in
            guard let `self` = self else { return }
            indexPathsForSelectedItems.forEach {
                self.resultsController.object(at: $0).isInTrash = true
                self.backgroundContext.saveIfNeeded()
            }
        }
    }
}

extension MainViewController: CNContactPickerDelegate {
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            self.bottomView.textView.selectedRange = self.selectedRange
            self.bottomView.textView.becomeFirstResponder()
            self.selectedRange = NSMakeRange(0, 0)
        }
        
    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            print(self.selectedRange)
            self.bottomView.textView.selectedRange = self.selectedRange
            self.bottomView.textView.becomeFirstResponder()
            //TODO: 언어 판별해서 name 순서 바꿔주기(공백 유무도)
            var str = self.bottomView.textView.text.count != 0 ? "\n☎️ " : "☎️ "
            str.append(contact.givenName + contact.familyName)
            
            if let phone = contact.phoneNumbers.first?.value.stringValue {
                str.append(" " + phone)
            }
            
            if let mail = contact.emailAddresses.first?.value as String? {
                str.append(" " + mail)
            }
            
            str.append("\n")
            
            self.bottomView.textView.insertText(str)
            
            self.selectedRange = NSMakeRange(0, 0)
        }
    }
}
