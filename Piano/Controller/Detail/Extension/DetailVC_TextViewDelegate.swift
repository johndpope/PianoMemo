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
        
//        이걸 안하면 글자색상이 띄어쓰거나 개행누를 때에도 입혀짐
        let trimText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimText.count == 0 {
            textView.typingAttributes = Preference.defaultTypingAttr
        }
        
        let bulletValue = BulletValue(text: textView.text, selectedRange: textView.selectedRange)
        
        //지우는 글자에 bullet이 포함되어 있다면
        if let bulletValue = bulletValue, textView.attributedText.attributedSubstring(from: range).string.contains(bulletValue.string) {
            let paraRange = (textView.text as NSString).paragraphRange(for: textView.selectedRange)
            textView.textStorage.addAttributes(Preference.defaultAttr, range: paraRange)
            textView.typingAttributes = Preference.defaultTypingAttr
        }
        
        
        var range = range
        if textView.shouldReset(bullet: bulletValue, range: range, replacementText: text) {
            textView.resetBullet(range: &range, bullet: bulletValue)
        }
        
        //        2. 개행일 경우 newLineOperation 체크하고 해당 로직 실행
        if textView.enterNewline(text) {
            
            //링크로 될 만한게 있나 디텍트하고 있다면 addAttributes
            let paraRange = (textView.text as NSString).paragraphRange(for: textView.selectedRange)
            textView.textStorage.addLinkAttr(searchRange: paraRange)

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
        detailToolbar.changeUndoBtnState()
        
        mineAttrString = textView.attributedText
        self.textView.hasEdit = true
        
        var selectedRange = textView.selectedRange
        var bulletKey = BulletKey(text: textView.text, selectedRange: selectedRange)
        if let uBullet = bulletKey {
            switch uBullet.type {
            case .orderedlist:
                textView.adjust(range: &selectedRange, bullet: &bulletKey)
                textView.transformTo(bullet: bulletKey)
                textView.adjustAfter(bullet: &bulletKey)
            default:
                textView.transformTo(bullet: bulletKey)
            }
        }
        
        let bulletValue = BulletValue(text: textView.text, selectedRange: textView.selectedRange)
        if let bullet = bulletValue, bullet.string == Preference.checklistOnValue {
            
            let paraRange = bullet.paraRange
            let location = bullet.baselineIndex
            let length = paraRange.upperBound - location
            let strikeThroughRange = NSMakeRange(location, length)
            textView.textStorage.addAttributes(Preference.strikeThroughAttr, range: strikeThroughRange)
        }
        
        if bulletValue == nil {
            let paraRange = (textView.text as NSString).paragraphRange(for: textView.selectedRange)
            if paraRange.lowerBound != textView.attributedText.length,
                let paraStyle = textView.attributedText.attribute(.paragraphStyle, at: paraRange.lowerBound, effectiveRange: nil) as? ParagraphStyle, paraStyle.headIndent != 0 {
                textView.textStorage.addAttributes(Preference.defaultAttr, range: paraRange)
            }
        }

        delayQueue.enqueue { [weak self] in
            guard let self = self else { return }
            self.saveNoteIfNeeded(textView: textView)
        }
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
    
//    func scrollViewWillBeginDragging(_ scrollView: ScrollView) {
//        guard let textView = scrollView as? DynamicTextView,
//            !textView.isSelectable,
//            let pianoControl = textView.pianoControl else { return }
//        
//        pianoControl.detach()
//    }
    
}

extension DetailViewController {
//    @objc func requestRecommand(_ sender: Any?) {
//        guard let textView = sender as? TextView else { return }
//        let recommandOperation = RecommandOperation(text: textView.text, selectedRange: textView.selectedRange) { [weak self] (recommandable) in
//        self?.detailBottomView.recommandData = recommandable
//        }
//        if recommandOperationQueue.operationCount > 0 {
//            recommandOperationQueue.cancelAllOperations()
//        }
//        recommandOperationQueue.addOperation(recommandOperation)
//    }
}
