//
//  BottomView_Action.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

extension BottomView {
    @IBAction func write(_ sender: Any) {
        guard let attrText = textView.attributedText, attrText.length != 0 else { return }
        resetTextView()

        AnalyticsHandler.logEvent(.creatNote, params: [
            "position": "bottomViewTextField",
            "length": attrText.length
            ])

        let strArray = attrText.string.components(separatedBy: .newlines)
        let strs = strArray.map { (str) -> String in
            if let pianoBullet = PianoBullet(type: .value, text: str, selectedRange: NSRange(location: 0, length: 0)) {
                return (str as NSString).replacingCharacters(in: pianoBullet.range, with: pianoBullet.key)
            } else {
                return str
            }
        }

        masterViewController?.bottomView(self, didFinishTyping: strs.joined(separator: "\n"))

    }

    @IBAction func createNewNote(_ sender: Any) {
        masterViewController?.bottomView(self, moveToDetailForNewNote: true)
        AnalyticsHandler.logEvent(.creatNote, params: [
            "position": "bottomViewButton"
            ])
    }
}

extension BottomView {
    private func resetTextView() {
        textView.text = ""
        textView.typingAttributes = Preference.defaultAttr
        sendButton.isHidden = textView.text.trimmingCharacters(in: .whitespacesAndNewlines).count == 0
        writeButton.isHidden = textView.text.trimmingCharacters(in: .whitespacesAndNewlines).count != 0
        textView.delegate?.textViewDidChange?(textView)
        masterViewController?.bottomView(self, textViewDidChange: textView)
        textView.resignFirstResponder()
    }
}
