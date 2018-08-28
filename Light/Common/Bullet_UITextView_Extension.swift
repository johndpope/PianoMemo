//
//  UITextView_delegate.swift
//  Block
//
//  Created by Kevin Kim on 2018. 7. 23..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation

extension TextView {
    internal func convertBulletForCurrentParagraphIfNeeded() {
        guard var bulletKey = BulletKey(text: text, selectedRange: selectedRange) else { return }
        
        switch bulletKey.type {
        case .orderedlist:
            adjust(&bulletKey)
            transform(bulletKey: bulletKey)
            adjustAfter(&bulletKey)
        default:
            transform(bulletKey: bulletKey)
        }
    }
    
    internal func convertBulletAllParagraphIfNeeded(){
        guard self.text.count != 0 else { return }
        let nsText = self.text as NSString
        var range = NSMakeRange(0, 0)
        
        while range.location < self.text.count {
            let paraRange = nsText.paragraphRange(for: range)
            guard let bulletValue = BulletValue(nsText: nsText, selectedRange: range) else { return }
            self.transform(bulletValue: bulletValue)
            range.location = paraRange.location + paraRange.length
        }
    }
    
    

}


/**
 FormManager의 역할을 임시로 여기로 빼 놓았는데, 이걸 어디다가 놓을 지 결정해야함
 */
extension TextView {
    internal func shouldReset(_ bulletValue: BulletValue, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let textViewText = self.text else { return true }
        if range.location < bulletValue.paraRange.location && (textViewText as NSString)
            .substring(with: (textViewText as NSString).paragraphRange(for: range))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .controlCharacters)
            .count != 0 {
            return true
            
        } else if text == "" && selectedRange.location == bulletValue.baselineIndex && selectedRange.length == 0 {
            return true
            
        } else if bulletValue.range.location < selectedRange.location
            && selectedRange.location < bulletValue.baselineIndex {
            return true
            
        } else if bulletValue.paraRange.location <= selectedRange.location
            && selectedRange.location <= bulletValue.range.location
            && text.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
            return true
            
        } else {
            return false
        }
    }
    
    internal func shouldDelete(_ bulletValue: BulletValue, replacementText text: String) -> Bool {
        return selectedRange.location == bulletValue.baselineIndex && text == "\n"
    }
    
    internal func shouldAdd(_ bulletValue: BulletValue, replacementText text: String) -> Bool {
        return selectedRange.location > bulletValue.baselineIndex && text == "\n"
    }
    
    internal func reset(_ bulletValue: BulletValue, range: NSRange) {
        switch bulletValue.type {
        case .orderedlist:
            //구두점을 포함해서 색상, 폰트, 커닝을 리셋한다.
            var resetRange = bulletValue.range
            resetRange.length += 1 //punctuation
            textStorage.addAttributes(Preference.defaultAttr, range: resetRange)
            
        default:
            //키로 바꿔주고 색상, 폰트를 리셋한다.
            let attrString = NSAttributedString(string: bulletValue.key, attributes: Preference.defaultAttr)
            textStorage.replaceCharacters(in: bulletValue.range, with: attrString)
            
        }
    }
    
    internal func delete(_ bulletValue: BulletValue) {
        let range = NSMakeRange(bulletValue.paraRange.location,
                                bulletValue.baselineIndex - bulletValue.paraRange.location)
        textStorage.replaceCharacters(in: range, with: "")
        if bulletValue.paraRange.location + bulletValue.paraRange.length < text.count {
            selectedRange.location -= range.length
        }
    }
    
    internal func add(_ bulletValue: BulletValue) {
        let range = NSMakeRange(
            bulletValue.paraRange.location,
            bulletValue.baselineIndex - bulletValue.paraRange.location)
        let mutableAttrString = NSMutableAttributedString(attributedString: attributedText.attributedSubstring(from: range))
        switch bulletValue.type {
        case .orderedlist:
            let relativeNumRange = NSMakeRange(bulletValue.range.location - range.location, bulletValue.range.length)
            guard let number = UInt(bulletValue.string) else { return }
            let nextNumber = number + 1
            mutableAttrString.replaceCharacters(
                in: relativeNumRange,
                with: String(nextNumber))
            
        default:
            ()
        }
        
        let newlineAttrString = NSMutableAttributedString(string: "\n", attributes: Preference.defaultAttr)
        newlineAttrString.addAttributes([.paragraphStyle : bulletValue.paragraphStyle],
                                        range: NSMakeRange(0, newlineAttrString.length))
        mutableAttrString.insert(newlineAttrString, at: 0)
        textStorage.replaceCharacters(in: selectedRange, with: mutableAttrString)
        selectedRange.location += mutableAttrString.length
        
    }
}

extension TextView {

}


extension TextView {
    internal func adjust(_ bulletKey: inout BulletKey) {
        guard let prevBulletKey = bulletKey.prevBullet(text: text),
        let prevNumber = UInt(prevBulletKey.string),
        prevBulletKey.type == .orderedlist,
        !prevBulletKey.isOverflow,
        bulletKey.whitespaces.string == prevBulletKey.whitespaces.string,
            !prevBulletKey.isSequencial(next: bulletKey) else { return }
        
        let numString = "\(prevNumber + 1)"
        textStorage.replaceCharacters(in: bulletKey.range, with: numString)
        selectedRange.location += numString.count - bulletKey.string.count
        
        if let adjustBulletKey = BulletKey(text: text, selectedRange: selectedRange) {
            bulletKey = adjustBulletKey
        }
    }
    
    //붙여넣기, 세팅을 위한 변형
    internal func transform(bulletValue: BulletValue) {
        guard !bulletValue.isOverflow else { return }
        switch bulletValue.type {
        case .orderedlist:
            textStorage.addAttributes([.font : Preference.numFont,
                                       .foregroundColor : Preference.effectColor], range: bulletValue.range)
            textStorage.addAttributes([
                .foregroundColor: Preference.punctuationColor,
                .kern: Preference.punctuationKern], range: NSMakeRange(bulletValue.baselineIndex - 2, 1))
        default:
            textStorage.addAttributes([.kern : Preference.kern(form: bulletValue.string)], range: bulletValue.range)
        }
        
        textStorage.addAttributes([.paragraphStyle : bulletValue.paragraphStyle],
                                  range: bulletValue.paraRange)
    }
    
    internal func transform(bulletKey: BulletKey) {
        guard !bulletKey.isOverflow else { return }
        switch bulletKey.type {
        case .orderedlist:
            textStorage.addAttributes([.font : Preference.numFont,
                                       .foregroundColor : Preference.effectColor], range: bulletKey.range)
            textStorage.addAttributes([
                .foregroundColor: Preference.punctuationColor,
                .kern: Preference.punctuationKern], range: NSMakeRange(bulletKey.baselineIndex - 2, 1))
        default:
            let value = bulletKey.value
            let attrString = NSAttributedString(string: bulletKey.value,
                                                attributes: [.font: Preference.defaultFont,
                                                             .kern : Preference.kern(form: value)])
            textStorage.replaceCharacters(in: bulletKey.range, with: attrString)
            selectedRange.location += (attrString.length - bulletKey.string.count)
        }
        
        textStorage.addAttributes([.paragraphStyle : bulletKey.paragraphStyle],
                                  range: bulletKey.paraRange)
    }
    
    internal func adjustAfter(_ bulletKey: inout BulletKey) {
        while bulletKey.paraRange.location + bulletKey.paraRange.length < attributedText.length {
            let range = NSMakeRange(bulletKey.paraRange.location + bulletKey.paraRange.length + 1, 0)
            guard let nextBullet = BulletKey(text: text, selectedRange: range),
                let currentNum = UInt(bulletKey.string),
                nextBullet.type == .orderedlist,
                !nextBullet.isOverflow,
                bulletKey.whitespaces.string == nextBullet.whitespaces.string,
                !bulletKey.isSequencial(next: nextBullet) else { return }
            
            let nextNum = currentNum + 1
            textStorage.replaceCharacters(in: nextBullet.range, with: "\(nextNum)")
            
            bulletKey = nextBullet
            
            guard let adjustNextBullet = BulletKey(text: text, selectedRange: range),
                !adjustNextBullet.isOverflow else { return }
            
            textStorage.addAttributes(
                [.font: Preference.numFont,
                 .foregroundColor: Preference.effectColor],
                range: adjustNextBullet.range)
            
            textStorage.addAttributes(
                [.foregroundColor: Preference.punctuationColor,
                 .kern: Preference.punctuationKern],
                range: adjustNextBullet.punctuationRange)
            
            textStorage.addAttributes(
                [.paragraphStyle: adjustNextBullet.paragraphStyle],
                range: adjustNextBullet.paraRange)
            
            bulletKey = adjustNextBullet

        }
    }
    
    
}
