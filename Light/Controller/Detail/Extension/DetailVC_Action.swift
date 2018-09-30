//
//  DetailVC_Action.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 2..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit
import ContactsUI
import CoreLocation

protocol ContainerDatasource {
    func reset()
    func startFetch()
    
}

extension DetailViewController {

    internal func setNavigationItems(state: VCState){
        var btns: [BarButtonItem] = []
        
        switch state {
        case .normal:
            navigationItem.titleView = nil
            navigationItem.setLeftBarButtonItems(nil, animated: false)
            defaultToolbar.isHidden = false
            completionToolbar.isHidden = true
        case .typing:
            btns.append(BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:))))
            let redo = BarButtonItem(image: #imageLiteral(resourceName: "redo"), style: .plain, target: self, action: #selector(redo(_:)))
            if let undoManager = textView.undoManager {
                redo.isEnabled = undoManager.canRedo
            }
            btns.append(redo)
            let undo = BarButtonItem(image: #imageLiteral(resourceName: "undo"), style: .plain, target: self, action: #selector(undo(_:)))
            if let undoManager = textView.undoManager {
                undo.isEnabled = undoManager.canUndo
            }
            btns.append(undo)
            
            navigationItem.titleView = nil
            navigationItem.setLeftBarButtonItems(nil, animated: false)
            defaultToolbar.isHidden = self.state != .merge ? false : true
            completionToolbar.isHidden = true
        case .piano:
            
            if let titleView = view.createSubviewIfNeeded(PianoTitleView.self) {
                navigationItem.titleView = titleView
            }
            
            let leftBtns = [BarButtonItem(title: "  ", style: .plain, target: nil, action: nil)]
            
            navigationItem.setLeftBarButtonItems(leftBtns, animated: false)
            defaultToolbar.isHidden = true
            completionToolbar.isHidden = false
        case .merge:
            navigationItem.titleView = nil
            navigationItem.setLeftBarButtonItems(nil, animated: false)
            defaultToolbar.isHidden = true
            completionToolbar.isHidden = true
        }
        
        navigationItem.setRightBarButtonItems(btns, animated: false)
    }
    
//    internal func setShareImage() {
//        if note.record()?.share != nil {
//            shareItem.image = #imageLiteral(resourceName: "addPeople2")
//        } else {
//            shareItem.image = #imageLiteral(resourceName: "addPeople")
//        }
//    }
    
    @IBAction func highlight(_ sender: Any) {
        Feedback.success()
        setupForPiano()
    }
    
    @IBAction func addPeople(_ sender: Any) {
        Feedback.success()
        guard let item = sender as? UIBarButtonItem else {return}
        if note.record()?.share == nil {
            cloudManager?.share.operate(target: self, pop: item, note: self.note, thumbnail: textView, title: "Text")
        } else {
            cloudManager?.share.configure(target: self, pop: item, note: self.note)
        }
    }
    
    @IBAction func copyText(_ sender: Any) {
        Feedback.success()
    }
    
    @IBAction func done(_ sender: Any) {
        Feedback.success()
        view.endEditing(true)
    }
    
    @IBAction func undo(_ sender: UIBarButtonItem) {
        guard let undoManager = textView.undoManager else { return }
        undoManager.undo()
        sender.isEnabled = undoManager.canUndo
    }
    
    @IBAction func redo(_ sender: UIBarButtonItem) {
        guard let undoManager = textView.undoManager else { return }
        undoManager.redo()
        sender.isEnabled = undoManager.canRedo
    }
        
    
    @IBAction func finishHighlight(_ sender: Any) {
        Feedback.success()
        setupForNormal()
        saveNoteIfNeeded(textView: textView)
    }
    
    
    
    @IBAction func trash(_ sender: Any) {
        
        if !UserDefaults.standard.bool(forKey: UserDefaultsKey.isExperiencedDeleteNote) {
            Alert.trash(from: self) { [weak self] in
                guard let `self` = self else { return }
                self.moveTrashAndPop()
                UserDefaults.standard.set(true, forKey: UserDefaultsKey.isExperiencedDeleteNote)
            }
            return
        }
            
        
        moveTrashAndPop()
    }
    
    private func moveTrashAndPop() {
        note.managedObjectContext?.performAndWait {
            note.isInTrash = true
            note.managedObjectContext?.saveIfNeeded()
        }
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func action(_ sender: Any) {
        
    }
    
    @IBAction func calendar(_ sender: UIButton) {
        guard !sender.isSelected else { return }
        accessoryButtons.forEach { $0.isSelected = $0 == sender }
        textInputView.frame.size.height = kbHeight
        textView.inputView = textInputView
        textView.reloadInputViews()
        textInputView.dataType = .event
        
        if !textView.isFirstResponder {
            textView.becomeFirstResponder()
        }
    }
    
    @IBAction func reminder(_ sender: UIButton) {
        guard !sender.isSelected else { return }
        accessoryButtons.forEach { $0.isSelected = $0 == sender }
        
        textInputView.frame.size.height = kbHeight
        textView.inputView = textInputView
        textView.reloadInputViews()
        textInputView.dataType = .reminder
        
        if !textView.isFirstResponder {
            textView.becomeFirstResponder()
        }
    }
    
    @IBAction func contact(_ sender: UIButton) {
        accessoryButtons.forEach { $0.isSelected = false }
        
        if textView.inputView != nil {
            textView.inputView = nil
            textView.reloadInputViews()
        }
        
        let vc = CNContactPickerViewController()
        vc.delegate = self
        selectedRange = textView.selectedRange
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func now(_ sender: UIButton) {
        accessoryButtons.forEach { $0.isSelected = false }
        
        if textView.inputView != nil {
            textView.inputView = nil
            textView.reloadInputViews()
        }
        
        textView.insertText(DateFormatter.longSharedInstance.string(from: Date()))
        
        if !textView.isFirstResponder {
            textView.becomeFirstResponder()
        }
    
        
    }
    
    @IBAction func location(_ sender: UIButton) {
        accessoryButtons.forEach { $0.isSelected = false }
        
        if textView.inputView != nil {
            textView.inputView = nil
            textView.reloadInputViews()
        }
        
        if !textView.isFirstResponder {
            textView.becomeFirstResponder()
        }
        
        
        Access.locationRequest(from: self, manager: locationManager) { [weak self] in
            self?.lookUpCurrentLocation(completionHandler: {[weak self] (placemark) in
                guard let `self` = self else { return }
                
                if let address = placemark?.postalAddress {
                    let str = CNPostalAddressFormatter.string(from: address, style: .mailingAddress).split(separator: "\n").reduce("", { (str, subStr) -> String in
                        return (str + " " + String(subStr))
                    })
                    self.textView.insertText(str)
                } else {
                    Alert.warning(from: self, title: "GPS 오류".loc, message: "디바이스가 위치를 가져오지 못하였습니다.".loc)
                }
            })
            
        }
    }
    
    @IBAction func plus(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        accessoryButtons.forEach { $0.isSelected = false }
        
        textAccessoryView.alpha = 0
        View.animate(withDuration: 0.2, animations: { [weak self] in
            guard let `self` = self else { return }
            self.textAccessoryView.isHidden = !sender.isSelected
            
        }) { [weak self] (_) in
            guard let `self` = self else { return }
            self.textAccessoryView.alpha = 1
        }
        
        if !sender.isSelected {
            textView.inputView = nil
            textView.reloadInputViews()
        }
        
        if sender.isSelected && !textView.isFirstResponder {
            textView.becomeFirstResponder()
        }
    }
    
    func lookUpCurrentLocation(completionHandler: @escaping (CLPlacemark?)
        -> Void ) {
        // Use the last reported location.
        if let lastLocation = locationManager.location {
            let geocoder = CLGeocoder()
            
            // Look up the location and pass it to the completion handler
            geocoder.reverseGeocodeLocation(lastLocation,
                                            completionHandler: { (placemarks, error) in
                                                if error == nil {
                                                    let firstLocation = placemarks?[0]
                                                    completionHandler(firstLocation)
                                                }
                                                else {
                                                    // An error occurred during geocoding.
                                                    completionHandler(nil)
                                                }
            })
        }
        else {
            // No location was available.
            completionHandler(nil)
        }
    }
}

extension DetailViewController: CLLocationManagerDelegate {
    
}


extension DetailViewController: CNContactPickerDelegate {
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            self.textView.selectedRange = self.selectedRange
            self.textView.becomeFirstResponder()
            self.selectedRange = NSMakeRange(0, 0)
        }
        
    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            print(self.selectedRange)
            self.textView.selectedRange = self.selectedRange
            self.textView.becomeFirstResponder()
            //TODO: 언어 판별해서 name 순서 바꿔주기(공백 유무도)
            var str = "☎️ "
            str.append(contact.givenName + contact.familyName)
            
            if let phone = contact.phoneNumbers.first?.value.stringValue {
                str.append(" " + phone)
            }
            
            if let mail = contact.emailAddresses.first?.value as String? {
                str.append(" " + mail)
            }
            
            str.append("\n")
            
            self.textView.insertText(str)
            
            self.selectedRange = NSMakeRange(0, 0)
        }
    }
}
