//
//  BottomView_TextViewDelegate.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation

extension BottomView: TextViewDelegate {
    
    func textViewDidChange(_ textView: TextView) {
        
        sendButton.isEnabled = textView.text.trimmingCharacters(in: .whitespacesAndNewlines).count != 0
        
        
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
        
        
        
        mainViewController?.bottomView(self, textViewDidChange: textView)
    }
    
    func textView(_ textView: TextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let trimText = text.trimmingCharacters(in: .newlines)
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
    
    func textViewDidChangeSelection(_ textView: TextView) {
        let paraRange = (textView.text as NSString).paragraphRange(for: textView.selectedRange)
        let paraText = textView.attributedText.attributedSubstring(from: paraRange).string
        
        DispatchQueue.global().async {
            if let recommandData = paraText.recommandData {
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    self.showRecommandView(data: recommandData)
                }
            }
        }
        
    }
    
    func showRecommandView(data: Recommandable) {
        
    }
    

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSAttributedStringKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.Key: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
