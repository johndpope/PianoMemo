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
        let bulletValue = BulletValue(text: textView.text, selectedRange: textView.selectedRange)
        var range = range
        if textView.shouldReset(bullet: bulletValue, range: range, replacementText: text) {
            textView.resetBullet(range: &range, bullet: bulletValue)
        }
        
        //        2. 개행일 경우 newLineOperation 체크하고 해당 로직 실행
        if textView.enterNewline(text) {
            
            if textView.shouldAddBullet(bullet: bulletValue, range: range) {
                textView.addBullet(range: &range, bullet: bulletValue)
                return false
            } else if textView.shouldDeleteBullet(bullet: bulletValue, range: range){
                textView.deleteBullet(range: &range, bullet: bulletValue)
                return false
            }
            
        }
        
        return true
    }
    
    func textViewDidChange(_ textView: TextView) {
        (textView as? DynamicTextView)?.hasEdit = true
        //TODO: date도 아이클라우드 전송에 맞추어서 등록
        note.modifiedDate = Date()
        
        var selectedRange = textView.selectedRange
        var bulletKey = BulletKey(text: textView.text, selectedRange: selectedRange)
        if let uBullet = bulletKey {
            switch uBullet.type {
            case .orderedlist:
                textView.adjust(range: &selectedRange, bullet: &bulletKey)
                textView.transformTo(bullet: &bulletKey)
                textView.adjustAfter(bullet: &bulletKey)
            default:
                textView.transformTo(bullet: &bulletKey)
            }
        }
    }
    
    func textViewDidBeginEditing(_ textView: TextView) {
        bottomButtons.forEach { $0.isSelected = false }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: ScrollView) {
        guard let textView = scrollView as? DynamicTextView,
            !textView.isSelectable,
            let pianoControl = textView.pianoControl,
            let pianoView = pianoView else { return }
        connect(pianoView: pianoView, pianoControl: pianoControl, textView: textView)
        pianoControl.attach(on: textView)
        
    }
    
    func scrollViewDidEndDragging(_ scrollView: ScrollView, willDecelerate decelerate: Bool) {
        guard let textView = scrollView as? DynamicTextView,
            !textView.isSelectable,
            let pianoControl = textView.pianoControl,
            let pianoView = pianoView else { return }
        
        connect(pianoView: pianoView, pianoControl: pianoControl, textView: textView)
        pianoControl.attach(on: textView)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: ScrollView) {
        guard let textView = scrollView as? DynamicTextView,
            !textView.isSelectable,
            let pianoControl = textView.pianoControl else { return }
        
        pianoControl.detach()
    }

}
