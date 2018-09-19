//
//  BottomView_Action.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation

extension BottomView {
    @IBAction func write(_ sender: Any) {
        guard textView.text.count != 0 else { return }
        mainViewController?.bottomView(self, didFinishTyping: textView.text)
        resetTextView()    
    }
}

extension BottomView {
    private func resetTextView() {
        textView.text = ""
        textView.typingAttributes = Preference.defaultAttr
        textView.delegate?.textViewDidChange?(textView)
    }
}
