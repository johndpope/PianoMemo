//
//  RecommandContactView.swift
//  Piano
//
//  Created by Kevin Kim on 20/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import Contacts

class RecommandContactView: UIView, RecommandDataAcceptable {
    
    weak var mainViewController: MainViewController?
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var phoneNumLabel: UILabel!
    @IBOutlet weak var mailLabel: UILabel!
    @IBOutlet weak var registerButton: UIButton!
    
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
        
        Access.contactRequest(from: vc) { [weak self] in
            guard let mutableContact = contact.mutableCopy() as? CNMutableContact else { return }
            let contactStore = CNContactStore()
            let request = CNSaveRequest()
            request.add(mutableContact, toContainerWithIdentifier: nil)
            do {
                try contactStore.execute(request)
                
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    self.perform(#selector(self.finishRegistering(_:)), with: textView, afterDelay: 0.7)
                    sender.setTitle("연락처에 등록 완료!", for: .normal)
                }
            } catch {
                print("RecommandContactView contact register 하다 에러: \(error.localizedDescription)")
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
