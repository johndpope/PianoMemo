//
//  LighteningVC_action.swift
//  Piano
//
//  Created by Kevin Kim on 08/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation
import ContactsUI
import CoreLocation

extension SmartWritingViewController {

    @IBAction func tapCancel(_ sender: Any) {
        textView.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tapEraseAll(_ sender: UIButton) {
        textView.text = ""
        textView.typingAttributes = Preference.defaultAttr
        textView.insertText("")
    }
    
    @IBAction func tapInfo(_ sender: UIButton) {
        let isHidden = sender.isSelected
        
        setHiddenGuideViews(isHidden: isHidden)
    }

    @IBAction func tapLocation(_ sender: Button) {
        Access.locationRequest(from: self, manager: locationManager) { [weak self] in
            guard let self = self else { return }
            self.setLocation(to: sender)
        }
    }

    @IBAction func tapCheck(_ sender: Button) {
        insertCheck()
    }

    @IBAction func tapTime(_ sender: UIButton) {
        insertTime(second: 60 * 60 * 24)
    }

    @IBAction func tapExpiredTime(_ sender: Any) {

    }

    @IBAction func tapSend(_ sender: Any) {
        guard let attrText = textView.attributedText, attrText.length != 0 else { return }
        let strArray = attrText.string.components(separatedBy: .newlines)
        let strs = strArray.map { (str) -> String in
            if let pianoBullet = PianoBullet(type: .value, text: str, selectedRange: NSRange(location: 0, length: 0)) {
                return (str as NSString).replacingCharacters(in: pianoBullet.range, with: pianoBullet.key)
            } else {
                return str
            }
        }
        //TODO: tags는 폴더가 만들어진 후에 뷰컨트롤러에 있는 폴더값을 대입해서 생성한다.
        // ex) create(content: ~~, folder: ~~)
        noteHandler?.create(content: strs.joined(separator: "\n"), tags: "", completion: nil)
        textView.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }

}
