//
//  DetailVC_TextViewDelegate.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation

extension NoteViewController: TextViewDelegate {
    func textView(_ textView: TextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let bulletValue = BulletValue(text: textView.text, selectedRange: textView.selectedRange) else { return true }
        
        if textView.shouldReset(bulletValue, shouldChangeTextIn: range, replacementText: text) {
            textView.reset(bulletValue, range: range)
            return true
        }
        
        if textView.shouldAdd(bulletValue, replacementText: text) {
            textView.add(bulletValue)
            return false
        }
        
        if textView.shouldDelete(bulletValue, replacementText: text) {
            textView.delete(bulletValue)
            return false
        }
        
        return true
    }
    
    func textViewDidChange(_ textView: TextView) {
        textView.convertBulletForCurrentParagraphIfNeeded()
    }
    
    func textViewDidEndEditing(_ textView: TextView) {
        textView.isEditable = false
    }
}
