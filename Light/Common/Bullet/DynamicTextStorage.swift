//
//  BulletTextStorage.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 7..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

class DynamicTextStorage: NSTextStorage {
    
    weak var textView: UITextView?
    
    private let backingStore = NSMutableAttributedString()
    
    override var string: String {
        return backingStore.string
    }
    
    func set(attributedString: NSAttributedString) {
        beginEditing()
        backingStore.setAttributedString(attributedString)
        edited([.editedCharacters, .editedAttributes], range: NSMakeRange(0, 0), changeInLength: attributedString.length)
        endEditing()
    }
    
    func paste() {
        
    }
    
    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedStringKey : Any] {
        return backingStore.attributes(at: location, effectiveRange: range)
    }
    
    override func replaceCharacters(in range: NSRange, with str: String) {

        beginEditing()
        backingStore.replaceCharacters(in: range, with:str)
        edited([.editedCharacters, .editedAttributes], range: range, changeInLength: str.utf16.count - range.length)
        endEditing()
        
    }
    
    override func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {

        //length가 있다는 건 영역이 잡혀있다는 말
        beginEditing()
        
        let cursorLocation = textView?.selectedRange.location ?? range.location
        let bulletValue = BulletValue(text: string, selectedRange: NSMakeRange(cursorLocation, 0))
        var range = range
        //백스페이스 range
        //1. 기존 문단 서식 지워주는 로직
        if shouldReset(bullet: bulletValue, range: range, attrString: attrString) {
            resetBullet(range: &range, bullet: bulletValue)
        }
    
        
//        2. 개행일 경우 newLineOperation 체크하고 해당 로직 실행
        if enterNewline(attrString) {
            
            if shouldAddBullet(bullet: bulletValue, range: range, attrString: attrString) {
                addBullet(range: &range, bullet: bulletValue)
                endEditing()
                return
            } else if shouldDeleteBullet(bullet: bulletValue, range: range, attrString: attrString) {
                deleteBullet(range: &range, bullet: bulletValue)
                endEditing()
                return
            }
        }
        
        
        let mutableAttrString = NSMutableAttributedString(attributedString: attrString)
        mutableAttrString.setAttributes(Preference.defaultAttr, range: NSMakeRange(0, attrString.length))
        

        backingStore.replaceCharacters(in: range, with: mutableAttrString)
        edited([.editedCharacters], range: range, changeInLength: mutableAttrString.length - range.length)
        
        //서식 입혀주기
        range.length = 0
        var bulletKey = BulletKey(text: string, selectedRange: range)
        if let uBullet = bulletKey {
            switch uBullet.type {
            case .orderedlist:
                adjust(range: &range, bullet: &bulletKey)
                transformTo(bullet: &bulletKey)
                adjustAfter(bullet: &bulletKey)
            default:
                transformTo(bullet: &bulletKey)
            }
        }
        
        
        
//        //패러그랲 붙여주고, 그 패러그랲 서식검사하고 이 순서로 가기
//        let mutableAttrString = NSMutableAttributedString(attributedString: attrString)
//        mutableAttrString.setAttributes(Preference.defaultAttr, range: NSMakeRange(0, mutableAttrString.length))
//        var paraRange = (mutableAttrString.string as NSString).paragraphRange(for: NSMakeRange(0, 0))
//
//        var bulletKey: BulletKey?
//        repeat {
//            let paraAttrString = mutableAttrString.attributedSubstring(from: paraRange)
//            backingStore.replaceCharacters(in: range, with: paraAttrString)
//            edited([.editedCharacters], range: range, changeInLength: paraAttrString.length - range.length)
//
//            //서식입혀주기
//            range.length = 0
//            bulletKey = BulletKey(text: string, selectedRange: range)
//            if let uBullet = bulletKey {
//                switch uBullet.type {
//                case .orderedlist:
//                    adjust(range: &range, bullet: &bulletKey)
//                    adjustAfter(bullet: &bulletKey)
//                default:
//                    replace(bullet: uBullet)
//
//                }
//                addAttributesTo(bullet: &bulletKey)
//
//
//            }
//
//            range.location += paraAttrString.length
//
//            paraRange = (mutableAttrString.string as NSString)
//                .paragraphRange(for: NSMakeRange(paraRange.location + paraRange.length, 0))
//
//        } while paraRange.location + paraRange.length < mutableAttrString.length
        
        endEditing()
    }
    
    override func addAttribute(_ name: NSAttributedStringKey, value: Any, range: NSRange) {
        
        beginEditing()
        backingStore.addAttribute(name, value: value, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }
    
    override func addAttributes(_ attrs: [NSAttributedStringKey : Any] = [:], range: NSRange) {
        
        beginEditing()
        backingStore.addAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }
    
    override func append(_ attrString: NSAttributedString) {
        
        beginEditing()
        let index = backingStore.length
        backingStore.append(attrString)
        edited([.editedAttributes,.editedCharacters], range: NSMakeRange(index, 0), changeInLength: attrString.length)
        endEditing()
    }
    
    override func insert(_ attrString: NSAttributedString, at loc: Int) {
        
        beginEditing()
        backingStore.insert(attrString, at: loc)
        edited([.editedAttributes,.editedCharacters], range: NSMakeRange(loc, 0), changeInLength: attrString.length)
        endEditing()
    }
    
    override func deleteCharacters(in range: NSRange) {
        
        beginEditing()
        backingStore.deleteCharacters(in: range)
        edited([.editedAttributes, .editedCharacters], range: range, changeInLength: -range.length)
        endEditing()
    }
    
    override func removeAttribute(_ name: NSAttributedStringKey, range: NSRange) {
        
        beginEditing()
        backingStore.removeAttribute(name, range: range)
        edited([.editedAttributes], range: range, changeInLength: 0)
        endEditing()
    }
    
    
    
    override func setAttributes(_ attrs: [NSAttributedStringKey : Any]?, range: NSRange) {
        
        beginEditing()
        backingStore.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

}

extension DynamicTextStorage {
    private func shouldReset(bullet: BulletValue?, range: NSRange, attrString: NSAttributedString) -> Bool {
        guard let uBullet = bullet else { return false }
        
        let string = self.string as NSString
        
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
        if range.location >= uBullet.paraRange.location && range.location <= uBullet.range.location && attrString.string.trimmingCharacters(in: .whitespacesAndNewlines).count != 0 {
            return true
        }
        
        
        return false
    }
    
    private func shouldDeleteBullet(bullet: BulletValue?, range: NSRange, attrString: NSAttributedString) -> Bool {
        
        guard let uBullet = bullet,
            range.location + range.length
                == uBullet.baselineIndex else { return false }
        return true
        
    }
    
    private func shouldAddBullet(bullet: BulletValue?, range: NSRange, attrString: NSAttributedString) -> Bool {
        
        guard let uBullet = bullet,
            range.location + range.length
                > uBullet.baselineIndex else { return false }
        
        return true
    }
    
    private func resetBullet(range: inout NSRange ,bullet: BulletValue?) {
        
        guard let uBullet = bullet else { return }
        switch uBullet.type {
        case .orderedlist:
            //문단 맨 앞에서부터 베이스라인까지 리셋해준다(패러그래프 스타일때문)
            let location = uBullet.paraRange.location
            let length = uBullet.baselineIndex - location
            let resetRange = NSMakeRange(location, length)
            backingStore.setAttributes(Preference.defaultAttr, range: resetRange)
            edited([.editedAttributes], range: resetRange, changeInLength: 0)
            
        default:
            //문단 맨 앞에서부터 베이스라인까지 리셋해준다(패러그래프 스타일때문)
            let attrString = NSAttributedString(string: uBullet.key, attributes: Preference.defaultAttr)
            
            backingStore.replaceCharacters(in: uBullet.range, with: attrString)
            let changeInLength = (attrString.length - uBullet.range.length)
            if range.upperBound > uBullet.range.location {
                range.location += changeInLength
                textView?.selectedRange.location += changeInLength
            }

            edited([.editedCharacters, .editedAttributes], range: uBullet.range, changeInLength: changeInLength)

        }
    }
    
    private func addBullet(range: inout NSRange, bullet: BulletValue?) {
        
        guard let uBullet = bullet else { return }
        
        let addRange = NSMakeRange(
            uBullet.paraRange.location,
            uBullet.baselineIndex - uBullet.paraRange.location)
        let mutableAttrString = NSMutableAttributedString(attributedString: backingStore.attributedSubstring(from: addRange))
        //checkOn일 경우 checkOff로 바꿔줌
        if mutableAttrString.string.contains(Preference.checkOnValue) {
            let location = uBullet.range.location - uBullet.paraRange.location
            let length = uBullet.baselineIndex - uBullet.range.location - 1
            let emojiRange = NSMakeRange(location, length)
            let checkOffAttrString = NSAttributedString(string: Preference.checkOffValue, attributes: Preference.emojiAttr(emoji: Preference.checkOffValue))
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
        backingStore.replaceCharacters(in: range, with: mutableAttrString)
        let changeInLength = mutableAttrString.length - range.length
        edited([.editedCharacters], range: range, changeInLength: changeInLength)
        range.location += changeInLength
        textView?.selectedRange.location += (mutableAttrString.length - 1)
        
    }
    
    private func deleteBullet(range: inout NSRange, bullet: BulletValue?) {

        guard let uBullet = bullet else { return }

        let deleteRange = NSMakeRange(
            uBullet.paraRange.location,
            uBullet.baselineIndex - uBullet.paraRange.location)
        
        backingStore.setAttributes(Preference.defaultAttr, range: deleteRange)

        backingStore.replaceCharacters(in: deleteRange, with: "")

        edited(
            [.editedCharacters, .editedAttributes],
            range: deleteRange,
            changeInLength: -deleteRange.length)
        range.location += (-deleteRange.length)

        if uBullet.paraRange.location + uBullet.paraRange.length < length {
            textView?.selectedRange.location -= (deleteRange.length + 1)
        }
    }

    private func enterNewline(_ attrString: NSAttributedString) -> Bool {
        return attrString.string == "\n"
    }

    private func adjust(range: inout NSRange, bullet: inout BulletKey?) {

        guard let uBullet = bullet,
            let prevBullet = uBullet.prevBullet(text: string),
            let prevNumber = UInt(prevBullet.string),
            prevBullet.type == .orderedlist,
            !prevBullet.isOverflow,
            uBullet.whitespaces.string == prevBullet.whitespaces.string,
            !prevBullet.isSequencial(next: uBullet) else { return }

        let numberString = "\(prevNumber + 1)"
        backingStore.replaceCharacters(in: uBullet.range, with: numberString)
        let changeInLength = numberString.count - uBullet.range.length
        edited([.editedCharacters], range: uBullet.range, changeInLength: changeInLength)

        textView?.selectedRange.location += changeInLength

        guard range.location > 0 else { return }
        if let adjustBullet = BulletKey(text: string, selectedRange: NSMakeRange(range.location, 0)) {
            bullet = adjustBullet
        }

    }

    private func transformTo(bullet: inout BulletKey?) {

        guard let bullet = bullet, !bullet.isOverflow else { return }

        switch bullet.type {
        case .orderedlist:
            let numRange = bullet.range
            backingStore.setAttributes(Preference.numAttr,range: numRange)
            edited([.editedAttributes],range: numRange, changeInLength: 0)

            let puncRange = NSMakeRange(bullet.baselineIndex - 2, 1)
            backingStore.setAttributes(Preference.punctuationAttr,range: puncRange)
            edited([.editedAttributes],range: puncRange, changeInLength: 0)
            
        default:
            let value = bullet.value
            let attrString = NSAttributedString(string: value, attributes: Preference.emojiAttr(emoji: value))
            backingStore.replaceCharacters(in: bullet.range, with: attrString)
            let changeInLength = attrString.length - bullet.range.length
            edited([.editedCharacters, .editedAttributes], range: bullet.range, changeInLength: changeInLength)
            textView?.selectedRange.location += changeInLength

        }
        
        let paraRange = NSMakeRange(bullet.paraRange.location,bullet.baselineIndex - bullet.paraRange.location)
        backingStore.addAttributes([.paragraphStyle : bullet.paragraphStyle], range: paraRange)
        edited(.editedAttributes, range: paraRange, changeInLength: 0)
    }

    private func adjustAfter(bullet: inout BulletKey?) {

        guard var uBullet = bullet else {
            return
        }

        while uBullet.paraRange.location + uBullet.paraRange.length < length {
            let range = NSMakeRange(uBullet.paraRange.location + uBullet.paraRange.length + 1, 0)
            guard let nextBullet = BulletKey(text: string, selectedRange: range),
                let currentNum = UInt(uBullet.string),
                nextBullet.type == .orderedlist,
                !nextBullet.isOverflow, uBullet.whitespaces.string == nextBullet.whitespaces.string,
                !uBullet.isSequencial(next: nextBullet) else { return }

            let nextNum = currentNum + 1
            backingStore.replaceCharacters(in: nextBullet.range, with: "\(nextNum)")
            edited([.editedCharacters], range: nextBullet.range, changeInLength: "\(nextNum)".count - nextBullet.range.length)

            bullet = nextBullet
            uBullet = nextBullet

            guard let adjustNextBullet = BulletKey(text: string, selectedRange: range),
                !adjustNextBullet.isOverflow else { return }

//            let blankString = backingStore.attributedSubstring(from: adjustNextBullet.range)
//            let width = blankString.size().width
//            let spaceCount = blankString.string.filter{$0 == " "}.count
//            let tabCount = blankString.string.filter{$0 == "\t"}.count
            
            
//            let paragraphStyle = FormAttributes.customMakeParagraphStyle?(adjustNextBullet, spaceCount, tabCount) ??
//                FormAttributes.makeParagraphStyle(bullet: adjustNextBullet, whitespaceWidth: width)

            backingStore.addAttributes(
                Preference.numAttr,
                range: adjustNextBullet.range)
            edited(
                [.editedAttributes],
                range: adjustNextBullet.range,
                changeInLength: 0)


            backingStore.addAttributes(
                Preference.punctuationAttr,
                range: NSMakeRange(adjustNextBullet.baselineIndex - 2, 1))
            edited(
                [.editedAttributes],
                range: NSMakeRange(adjustNextBullet.baselineIndex - 2, 1),
                changeInLength: 0)

            uBullet = adjustNextBullet
            bullet = adjustNextBullet
        }

    }

//    private func replace(bullet: BulletKey) {
//
//        backingStore.replaceCharacters(in: bullet.range, with: bullet.value)
//        edited([.editedCharacters], range: bullet.range, changeInLength: convertedString.count - bullet.range.length)
//
//        DispatchQueue.main.async { [weak self] in
//            self?.textView?.selectedRange.location += (convertedString.count - bullet.range.length)
//        }
//
//    }
}
