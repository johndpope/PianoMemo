//
//  RecommandAddressViewController.swift
//  Piano
//
//  Created by Kevin Kim on 03/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import ContactsUI

class RecommandAddressViewController: UIViewController, RecommandDataAcceptable {
    weak var viewController: ViewController?
    weak var textView: TextView?
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet var buttons: [UIButton]!
    var selectedRange = NSMakeRange(0, 0)
    
    var data: Recommandable? {
        didSet {
            
            DispatchQueue.main.async { [ weak self] in
                guard let `self` = self, let contact = self.data as? CNContact else { return }
                self.nameLabel.text = contact.givenName + " " + contact.familyName
                self.nameLabel.text = (contact.givenName + " " + contact.familyName).trimmingCharacters(in: .whitespacesAndNewlines).count != 0
                    ? contact.givenName + " " + contact.familyName
                    : "이름 없음".loc
                
                if let address = contact.postalAddresses.first?.value {
                    let str = CNPostalAddressFormatter.string(from: address, style: .mailingAddress).split(separator: "\n").reduce("", { (str, subStr) -> String in
                        return (str + " " + String(subStr))
                    })
                    
                    self.addressLabel.text = str
                }
            }
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        buttons.forEach { $0.isHidden = true }
        
        Preference.locationTags.enumerated().forEach { (offset, str) in
            buttons[offset].setTitle(str, for: .normal)
            buttons[offset].isHidden = false
        }
    }
    
    @IBAction func register(_ sender: UIButton) {
        guard let vc = viewController,
            let contact = data as? CNContact,
            let mutableContact = contact.mutableCopy() as? CNMutableContact,
            let textView = textView else { return }
        selectedRange = textView.selectedRange
        
        if let str = sender.titleLabel?.text {
            mutableContact.familyName = str
        }
        
        Access.contactRequest(from: vc) {
            let contactStore = CNContactStore()
            DispatchQueue.main.async {
                let contactVC = CNContactViewController(forNewContact: mutableContact)
                contactVC.contactStore = contactStore
                contactVC.delegate = self
                let nav = UINavigationController()
                nav.viewControllers = [contactVC]
                vc.present(nav, animated: true, completion: nil)
            }
        }
    }
    
}

extension RecommandAddressViewController: CNContactViewControllerDelegate {
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        if contact == nil {
            //cancel
            viewController.dismiss(animated: true, completion: nil)
            textView?.becomeFirstResponder()
        } else {
            //save
            viewController.dismiss(animated: true, completion: nil)
            deleteParagraphAndfireNotification(contact: contact)
        }
        
    }
    
    private func deleteParagraphAndfireNotification(contact: CNContact?) {
        guard let vc = viewController,
            let textView = textView else { return }
        
        let paraRange = (textView.text as NSString).paragraphRange(for: selectedRange)
        textView.textStorage.replaceCharacters(in: paraRange, with: "")
        textView.typingAttributes = Preference.defaultAttr
        textView.delegate?.textViewDidChange?(textView)
        
        
        
        
        
        let message = "✨장소가 등록되었어요✨".loc
//        (mainVC.navigationController as? TransParentNavigationController)?.show(message: message)
    }
}
