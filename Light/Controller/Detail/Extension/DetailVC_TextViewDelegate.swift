//
//  DetailVC_TextViewDelegate.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation

extension DetailViewController: TextViewDelegate {
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
        
        //TODO: 현재 버그를 임시로 해결한 코드인데 이거 해결해야함.
        if text == "" && textView.selectedRange.location == bulletValue.baselineIndex && textView.selectedRange.length != 0 {
            textView.textStorage.replaceCharacters(in: textView.selectedRange, with: "")
            textView.selectedRange.length = 0
            return false
            
        }
        
        return true
    }
    
    func textViewDidChange(_ textView: TextView) {
        textView.convertBulletForCurrentParagraphIfNeeded()
        (textView as? LightTextView)?.hasEdit = true
    }
    
    func textViewDidEndEditing(_ textView: TextView) {
        textView.isEditable = false
    }
    
    func textViewDidBeginEditing(_ textView: TextView) {
        bottomButtons.forEach { $0.isSelected = false }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: ScrollView) {
        guard let textView = scrollView as? LightTextView,
            !textView.isSelectable,
            let pianoControl = textView.pianoControl,
            let pianoView = pianoView else { return }
        connect(pianoView: pianoView, pianoControl: pianoControl, textView: textView)
        pianoControl.attach(on: textView)
        
    }
    
    func scrollViewDidEndDragging(_ scrollView: ScrollView, willDecelerate decelerate: Bool) {
        guard let textView = scrollView as? LightTextView,
            !textView.isSelectable,
            let pianoControl = textView.pianoControl,
            let pianoView = pianoView else { return }
        
        connect(pianoView: pianoView, pianoControl: pianoControl, textView: textView)
        pianoControl.attach(on: textView)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: ScrollView) {
        guard let textView = scrollView as? LightTextView,
            !textView.isSelectable,
            let pianoControl = textView.pianoControl else { return }
        
        pianoControl.detach()
    }

}
