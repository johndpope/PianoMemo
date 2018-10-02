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
    
    weak var mainViewController: MainViewController?
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var firstAddressButton: UIButton!
    @IBOutlet weak var secondAddressButton: UIButton!
    @IBOutlet weak var thirdAddressButton: UIButton!
    @IBOutlet weak var fourthAddressButton: UIButton!
    @IBOutlet weak var fifthAddressButton: UIButton!
    var selectedRange = NSMakeRange(0, 0)
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        setup()
    }
    
    private func setup(){
        firstAddressButton.setTitle(Preference.firstAddressEmoji, for: .normal)
        secondAddressButton.setTitle(Preference.secondAddressEmoji, for: .normal)
        thirdAddressButton.setTitle(Preference.thirdAddressEmoji, for: .normal)
        fourthAddressButton.setTitle(Preference.fourthAddressEmoji, for: .normal)
        fifthAddressButton.setTitle(Preference.fifthAddressEmoji, for: .normal)
    }
    
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
                        return (str + " " + String(subStr))
                    })
                    
                    self.addressLabel.text = str
                }
                
                
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

extension RecommandAddressView: CNContactViewControllerDelegate {
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
        
        let message = "✨주소가 등록되었어요✨".loc
        (mainVC.navigationController as? TransParentNavigationController)?.show(message: message)
    }
}
