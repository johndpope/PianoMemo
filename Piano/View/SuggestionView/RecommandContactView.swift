//
//  RecommandContactView.swift
//  Piano
//
//  Created by Kevin Kim on 20/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import ContactsUI

class RecommandContactView: UIView, RecommandDataAcceptable {

    private weak var viewController: ViewController?
    private weak var textView: TextView?

    func setup(viewController: ViewController, textView: TextView) {
        self.viewController = viewController
        self.textView = textView
    }

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var phoneNumLabel: UILabel!
    @IBOutlet weak var mailLabel: UILabel!
    @IBOutlet weak var registerButton: UIButton!
    var selectedRange = NSRange(location: 0, length: 0)

    var data: Recommandable? {
        didSet {

            DispatchQueue.main.async { [ weak self] in
                guard let `self` = self else { return }

                guard let contact = self.data as? CNContact else {
                    self.isHidden = true
                    return
                }
                self.isHidden = false
                let westernStyle = contact.givenName + " " + contact.familyName
                let easternStyle = contact.familyName + contact.givenName
                var str = ""
                if let language = westernStyle.detectedLangauge(), language.contains("Japanese") || language.contains("Chinese") || language.contains("Korean") {
                    str = easternStyle
                } else {
                    str = westernStyle
                }

                let nameText = str.trimmingCharacters(in: .whitespacesAndNewlines).count != 0
                    ? str
                    : "No name".loc

                self.nameLabel.text = nameText

                if let phoneNumStr = contact.phoneNumbers.first?.value.stringValue {
                    self.phoneNumLabel.text = phoneNumStr
                } else {
                    self.phoneNumLabel.text = "No phone number".loc
                }

                if let mailStr = contact.emailAddresses.first?.value as String? {
                    self.mailLabel.text = mailStr
                } else {
                    self.mailLabel.text = "No mail".loc
                }
            }

        }
    }

    @IBAction func register(_ sender: UIButton) {
        guard let viewController = viewController,
            let textView = textView,
            let contact = data as? CNContact else { return }
        selectedRange = textView.selectedRange

        Access.contactRequest(from: viewController) { [weak self] in

            DispatchQueue.main.async { [weak self] in
                guard let self = self,
                    let mutableContact = contact.mutableCopy() as? CNMutableContact else { return }

                let contactStore = CNContactStore()
                let saveRequest = CNSaveRequest()

                saveRequest.add(mutableContact, toContainerWithIdentifier: nil)
                do {
                    try contactStore.execute(saveRequest)
                    let message = "☎️ Your contacts are successfully registered✨".loc
                    self.viewController?.transparentNavigationController?.show(message: message, color: Color.point)
                    self.finishRegistering(textView)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }

    func finishRegistering(_ textView: TextView) {
        let paraRange = (textView.text as NSString).paragraphRange(for: textView.selectedRange)
        textView.replaceCharacters(in: paraRange, with: NSAttributedString(string: "", attributes: FormAttribute.defaultAttr))
        textView.typingAttributes = Preference.defaultAttr
    }

}
