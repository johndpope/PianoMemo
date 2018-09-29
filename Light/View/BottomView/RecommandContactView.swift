//
//  RecommandContactView.swift
//  Piano
//
//  Created by Kevin Kim on 20/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import ContactsUI
import Lottie

class RecommandContactView: UIView, RecommandDataAcceptable {
    
    weak var mainViewController: MainViewController?
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var phoneNumLabel: UILabel!
    @IBOutlet weak var mailLabel: UILabel!
    @IBOutlet weak var registerButton: UIButton!
    var selectedRange = NSMakeRange(0, 0)
    
    var data: Recommandable? {
        didSet {
            
            DispatchQueue.main.async { [ weak self] in
                guard let `self` = self else { return }
                
                guard let contact = self.data as? CNContact else {
                    self.isHidden = true
                    return
                }
                self.isHidden = false
                self.nameLabel.text = contact.givenName + " " + contact.familyName
                
                self.nameLabel.text = (contact.givenName + " " + contact.familyName).trimmingCharacters(in: .whitespacesAndNewlines).count != 0
                    ? contact.givenName + " " + contact.familyName
                    : "이름 없음".loc
                
                
                if let phoneNumStr = contact.phoneNumbers.first?.value.stringValue {
                    self.phoneNumLabel.text = phoneNumStr
                } else {
                    self.phoneNumLabel.text = "휴대폰 번호 없음"
                }
                
                if let mailStr = contact.emailAddresses.first?.value as String? {
                    self.mailLabel.text = mailStr
                } else {
                    self.mailLabel.text = "메일 없음"
                }
                
                self.registerButton.setTitle("터치하여 연락처에 등록해보세요.", for: .normal)
                
            }
        
        }
    }
    
    @IBAction func register(_ sender: UIButton) {
        guard let vc = mainViewController,
            let contact = data as? CNContact,
            let textView = vc.bottomView.textView else { return }
        selectedRange = textView.selectedRange
        
        Access.contactRequest(from: vc) { [weak self] in
            let contactStore = CNContactStore()
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                
                let vc = CNContactViewController(forNewContact: contact)
                vc.contactStore = contactStore
                vc.delegate = self
                let nav = UINavigationController()
                nav.viewControllers = [vc]
                self.mainViewController?.present(nav, animated: true, completion: nil)
            }
        }
    }
    
    @objc func finishRegistering(_ textView: TextView) {
        
        
        let paraRange = (textView.text as NSString).paragraphRange(for: textView.selectedRange)
        textView.textStorage.replaceCharacters(in: paraRange, with: "")
        textView.typingAttributes = Preference.defaultAttr
        isHidden = true
    }
    
}
extension RecommandContactView: CNContactViewControllerDelegate {
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        if contact == nil {
            //cancel
            viewController.dismiss(animated: true, completion: nil)
            mainViewController?.bottomView.textView.becomeFirstResponder()
        } else {
            //save
            viewController.dismiss(animated: true, completion: nil)
            
            deleteParagraphAndAnimateHUD(contact: contact)
        }
        
    }
    
    private func deleteParagraphAndAnimateHUD(contact: CNContact?) {
        guard let mainVC = mainViewController,
            let textView = mainVC.bottomView.textView else { return }
        
        let paraRange = (textView.text as NSString).paragraphRange(for: selectedRange)
        textView.textStorage.replaceCharacters(in: paraRange, with: "")
        textView.typingAttributes = Preference.defaultAttr
        mainVC.bottomView.textViewDidChange(textView)
        isHidden = true
        
        let message = "✨연락처가 등록되었어요✨".loc
        TextNotification.showMessage(navigationController: mainVC.navigationController, message: message)
    }
}
