//
//  UITextView_Bullet.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 8..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

extension UITextView {
    internal func shouldReset(bullet: BulletValue?, range: NSRange, replacementText text: String) -> Bool {
        guard let uBullet = bullet else { return false }
        
        let string = self.text as NSString
        
        //이전문단으로 가는데 이전 문단에 문자열이 있을 경우
        if ((range.location < uBullet.paraRange.location
            && string.substring(with: string.paragraphRange(for: range))
                .trimmingCharacters(in: .whitespacesAndNewlines).count != 0)) {
            return true
        }
        
        //range.location이 bulletAndSpace의 왼쪽보다 크고, 오른쪽보다 작은 위치에 있다면 무조건 리셋
        if range.location > uBullet.range.location && range.location < uBullet.baselineIndex {
            return true
        }
        
        //whitespace범위에 whitespaceAndNewline이 아닌 글자를 입력한 경우 리셋
        if range.location >= uBullet.paraRange.location && range.location <= uBullet.range.location && text.trimmingCharacters(in: .whitespacesAndNewlines).count != 0 {
            return true
        }
        
        return false
    }
    
    internal func shouldDeleteBullet(bullet: BulletValue?, range: NSRange) -> Bool {
        
        guard let uBullet = bullet,
            range.location + range.length
                == uBullet.baselineIndex else { return false }
        return true
        
    }
    
    internal func shouldAddBullet(bullet: BulletValue?, range: NSRange) -> Bool {
        
        guard let uBullet = bullet,
            range.location + range.length
                > uBullet.baselineIndex else { return false }
        
        return true
    }
    
    internal func resetBullet(range: inout NSRange ,bullet: BulletValue?) {
        
        guard let uBullet = bullet else { return }
        switch uBullet.type {
        case .orderedlist:
            //문단 맨 앞에서부터 베이스라인까지 리셋해준다(패러그래프 스타일때문)
            let location = uBullet.paraRange.location
            let length = uBullet.baselineIndex - location
            let resetRange = NSMakeRange(location, length)
            textStorage.addAttributes(Preference.defaultAttr, range: resetRange)
            
        default:
            textStorage.addAttributes(Preference.defaultAttr, range: uBullet.paraRange)
            //문단 맨 앞에서부터 베이스라인까지 리셋해준다(패러그래프 스타일때문)
            let attrString = NSAttributedString(string: uBullet.key, attributes: Preference.defaultAttr)
            textStorage.replaceCharacters(in: uBullet.range, with: attrString)
            let changeInLength = (attrString.length - uBullet.range.length)
            if (range.upperBound > uBullet.range.location) {
                range.location += changeInLength
                if (attributedText.length != range.upperBound) {
                    selectedRange.location += changeInLength
                }
            }
            
            
        }
    }
    
    internal func addBullet(range: inout NSRange, bullet: BulletValue?) {
        
        guard let uBullet = bullet else { return }
        
        let addRange = NSMakeRange(
            uBullet.paraRange.location,
            uBullet.baselineIndex - uBullet.paraRange.location)
        let mutableAttrString = NSMutableAttributedString(attributedString: attributedText.attributedSubstring(from: addRange))
        //checkOn일 경우 checkOff로 바꿔줌
        if mutableAttrString.string.contains(Preference.checklistOnValue) {
            let location = uBullet.range.location - uBullet.paraRange.location
            let length = uBullet.baselineIndex - uBullet.range.location - 1
            let emojiRange = NSMakeRange(location, length)
            let checkOffAttrString = NSAttributedString(string: Preference.checklistOffValue, attributes: Preference.formAttr(form: Preference.checklistOffValue))
            mutableAttrString.replaceCharacters(in: emojiRange, with: checkOffAttrString)
        }
        
        
        switch uBullet.type {
        case .orderedlist:
            let relativeNumRange = NSMakeRange(uBullet.range.location - addRange.location, uBullet.range.length)
            guard let number = UInt(uBullet.string) else { return }
            let nextNumber = number + 1
            mutableAttrString.replaceCharacters(
                in: relativeNumRange,
                with: String(nextNumber))
            
            
        default:
            //나머지는 그대로 진행하면 됨
            ()
        }
        let enter = NSAttributedString(string: "\n", attributes: Preference.defaultAttr)
        mutableAttrString.insert(enter, at: 0)
        textStorage.replaceCharacters(in: range, with: mutableAttrString)
        let changeInLength = mutableAttrString.length - range.length
        range.location += changeInLength
        selectedRange.location += (mutableAttrString.length)
        
    }
    
    internal func deleteBullet(range: inout NSRange, bullet: BulletValue?) {
        
        guard let uBullet = bullet else { return }
        
        let deleteRange = NSMakeRange(
            uBullet.paraRange.location,
            uBullet.baselineIndex - uBullet.paraRange.location)
        
        //        textStorage.setAttributes(LocalPreference.defaultAttr, range: deleteRange)
        
        textStorage.replaceCharacters(in: deleteRange, with: "")
        
        range.location += (-deleteRange.length)
        
        
        
        if uBullet.paraRange.location + uBullet.paraRange.length < attributedText.length {
            selectedRange.location -= (deleteRange.length)
        }
        
        typingAttributes = Preference.defaultTypingAttr
    }
    
    internal func enterNewline(_ text: String) -> Bool {
        return text == "\n"
    }
    
    internal func adjust(range: inout NSRange, bullet: inout BulletKey?) {
        
        guard let uBullet = bullet,
            let prevBullet = uBullet.prevBullet(text: self.text),
            let prevNumber = UInt(prevBullet.string),
            prevBullet.type == .orderedlist,
            !prevBullet.isOverflow,
            uBullet.whitespaces.string == prevBullet.whitespaces.string,
            !prevBullet.isSequencial(next: uBullet) else { return }
        
        let numberString = "\(prevNumber + 1)"
        textStorage.replaceCharacters(in: uBullet.range, with: numberString)
        let changeInLength = numberString.count - uBullet.range.length
        
        
        selectedRange.location += changeInLength
        
        guard range.location > 0 else { return }
        if let adjustBullet = BulletKey(text: self.text, selectedRange: NSMakeRange(range.location, 0)) {
            bullet = adjustBullet
        }
        
    }
    
    internal func transformTo(bullet: BulletKey?) {
        
        guard let bullet = bullet, !bullet.isOverflow else { return }
        
        switch bullet.type {
        case .orderedlist:
            //이미 입혀진 거라면 리턴
            if let kern = attributedText
                .attributedSubstring(from: bullet.punctuationRange)
                .attribute(.kern, at: 0, effectiveRange: nil) as? Float,
                kern != 0 {
                return
            }
            let numRange = bullet.range
            textStorage.addAttributes(Preference.numAttr,range: numRange)
            
            let puncRange = NSMakeRange(bullet.baselineIndex - 2, 1)
            textStorage.addAttributes(Preference.punctuationAttr(num: bullet.string),range: puncRange)
            
        default:
            let value = bullet.value
            let attrString = NSAttributedString(string: value, attributes: Preference.formAttr(form: value))
            textStorage.replaceCharacters(in: bullet.range, with: attrString)
            let changeInLength = attrString.length - bullet.range.length
            selectedRange.location += changeInLength
            
            if value == Preference.checklistOnValue {
                
                let valueRange = NSMakeRange(bullet.baselineIndex + changeInLength, bullet.paraRange.upperBound - bullet.baselineIndex)
                textStorage.addAttributes(Preference.strikeThroughAttr, range: valueRange)
                typingAttributes = Preference.strikeThroughAttr
            }
            
        }
        
        let paraRange = NSMakeRange(bullet.paraRange.location, bullet.baselineIndex - bullet.paraRange.location)
        textStorage.addAttributes([.paragraphStyle : bullet.paragraphStyle], range: paraRange)
    }
    
    internal func adjustAfter(bullet: inout BulletKey?) {
        
        guard var uBullet = bullet else {
            return
        }
        
        while uBullet.paraRange.location + uBullet.paraRange.length < attributedText.length {
            let range = NSMakeRange(uBullet.paraRange.location + uBullet.paraRange.length + 1, 0)
            guard let nextBullet = BulletKey(text: self.text, selectedRange: range),
                let currentNum = UInt(uBullet.string),
                nextBullet.type == .orderedlist,
                !nextBullet.isOverflow, uBullet.whitespaces.string == nextBullet.whitespaces.string,
                !uBullet.isSequencial(next: nextBullet) else { return }
            
            let nextNum = currentNum + 1
            textStorage.replaceCharacters(in: nextBullet.range, with: "\(nextNum)")
            
            bullet = nextBullet
            uBullet = nextBullet
            
            guard let adjustNextBullet = BulletKey(text: self.text, selectedRange: range),
                !adjustNextBullet.isOverflow else { return }
            
            textStorage.addAttributes(
                Preference.numAttr,
                range: adjustNextBullet.range)
            
            
            textStorage.addAttributes(
                Preference.punctuationAttr(num: adjustNextBullet.string),
                range: NSMakeRange(adjustNextBullet.baselineIndex - 2, 1))
            
            uBullet = adjustNextBullet
            bullet = adjustNextBullet
        }
        
    }
    
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSAttributedStringKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.Key: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
