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
        masterViewController?.bottomView(self, didFinishTyping: attrText.string)

    }

    @IBAction func createNewNote(_ sender: Any) {
        masterViewController?.bottomView(self, moveToDetailForNewNote: true)
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
