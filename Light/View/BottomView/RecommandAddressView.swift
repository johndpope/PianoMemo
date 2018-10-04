//
//  RecommandAddressView.swift
//  Piano
//
//  Created by Kevin Kim on 27/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import ContactsUI

class RecommandAddressView: UIView, RecommandDataAcceptable {
    
    private weak var viewController: ViewController?
    private weak var textView: TextView?
    
    func setup(viewController: ViewController, textView: TextView) {
        self.viewController = viewController
        self.textView = textView
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
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
                
                if let address = contact.postalAddresses.first?.value {
                    let str = CNPostalAddressFormatter.string(from: address, style: .mailingAddress).split(separator: "\n").reduce("", { (str, subStr) -> String in
                        guard str.count != 0 else { return String(subStr) }
                        return (str + " " + String(subStr))
                    })
                    
                    self.addressLabel.text = str
                }
            }
        }
    }
    
    @IBAction func register(_ sender: UIButton) {
        guard let viewController = viewController,
            let textView = textView,
            let contact = data as? CNContact,
            let mutableContact = contact.mutableCopy() as? CNMutableContact
             else { return }
        selectedRange = textView.selectedRange
        
        mutableContact.familyName = Preference.locationTags.reduce("", +)
        
        Access.contactRequest(from: viewController) { [weak self] in
            let contactStore = CNContactStore()
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                
                let contactVC = CNContactViewController(forNewContact: mutableContact)
                contactVC.contactStore = contactStore
                contactVC.delegate = self
                let nav = UINavigationController()
                nav.viewControllers = [contactVC]
                viewController.present(nav, animated: true, completion: nil)
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

extension RecommandAddressView: CNContactViewControllerDelegate {
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        if contact == nil {
            //cancel
            viewController.dismiss(animated: true, completion: nil)
            textView?.becomeFirstResponder()
        } else {
            //save
            viewController.dismiss(animated: true, completion: nil)
            deleteParagraphAndAnimateHUD(contact: contact)
        }
        
    }
    
    private func deleteParagraphAndAnimateHUD(contact: CNContact?) {
        guard let viewController = viewController,
            let textView = textView else { return }
        
        let paraRange = (textView.text as NSString).paragraphRange(for: selectedRange)
        textView.textStorage.replaceCharacters(in: paraRange, with: "")
        textView.typingAttributes = Preference.defaultAttr
        textView.delegate?.textViewDidChange?(textView)
        isHidden = true
        
        let message = "✨장소가 등록되었어요✨".loc
        viewController.transparentNavigationController?.show(message: message)
    }
}
