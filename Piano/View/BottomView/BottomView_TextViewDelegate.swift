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

        sendButton.isHidden = textView.text.trimmingCharacters(in: .whitespacesAndNewlines).count == 0
        writeButton.isHidden = textView.text.trimmingCharacters(in: .whitespacesAndNewlines).count != 0
        eraseButton.isEnabled = (masterViewController?.textAccessoryVC?.collectionView.indexPathsForSelectedItems?.count ?? 0) != 0 || textView.text.count != 0
        masterViewController?.bottomView(self, textViewDidChange: textView)

        var selectedRange = textView.selectedRange
        var bulletKey = PianoBullet(type: .shortcut, text: textView.text, selectedRange: selectedRange)
        if let key  = bulletKey {
            if key.isOrdered {
                textView.adjust(range: &selectedRange, bullet: &bulletKey)
                textView.transformTo(bullet: bulletKey)
                textView.adjustAfter(bullet: &bulletKey)
            } else {
                textView.transformTo(bullet: bulletKey)
            }
        }

        if bulletKey == nil {
            let paraRange = (textView.text as NSString).paragraphRange(for: textView.selectedRange)
            if paraRange.lowerBound != textView.attributedText.length,
                let paraStyle = textView.attributedText.attribute(.paragraphStyle, at: paraRange.lowerBound, effectiveRange: nil) as? ParagraphStyle, paraStyle.headIndent != 0 {
                textView.textStorage.addAttributes(Preference.defaultAttr, range: paraRange)
            }
        }

    }

    func textView(_ textView: TextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let trimText = text.trimmingCharacters(in: .newlines)
        if trimText.count == 0 {
            textView.typingAttributes = Preference.defaultTypingAttr
        }

        let bulletValue = PianoBullet(type: .value, text: textView.text, selectedRange: textView.selectedRange)

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
            } else if textView.shouldDeleteBullet(bullet: bulletValue, range: range) {
                textView.deleteBullet(range: &range, bullet: bulletValue)
                return false
            }

        }
        return true

    }

}
