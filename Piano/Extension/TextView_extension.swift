//
//  TextView_extension.swift
//  Piano
//
//  Created by Kevin Kim on 18/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

extension TextView {

    /**
     역할
     1. undo 등록
     2. 글자 대체
     3. 델리게이트 노티
     4. selectedRange변경
     5. 아래로 스크롤
     */

    internal func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {
        registerUndo(attrString: attrString, selectedRange: range)
        textStorage.replaceCharacters(in: range, with: attrString)
        delegate?.textViewDidChange?(self)
        let newSelectedRange = NSRange(location: range.location + attrString.length, length: 0)
        selectedRange = newSelectedRange
    }

    internal func replaceHighlightedTextToEmpty() {
        var highlightedRanges: [NSRange] = []
        attributedText.enumerateAttribute(.backgroundColor, in: NSRange(location: 0, length: attributedText.length), options: .reverse) { (value, range, _) in
            guard let color = value as? Color, color == Color.highlight else { return }
            highlightedRanges.append(range)
        }

        highlightedRanges.forEach {
            textStorage.addAttributes([.backgroundColor: Color.clear], range: $0)
        }

        let attrStringTuples = highlightedRanges.map {
            ($0, attributedText.attributedSubstring(from: $0)) }
        registerUndoForCut(tuples: attrStringTuples)

        highlightedRanges.forEach {
            textStorage.replaceCharacters(in: $0, with: "")
        }

        delegate?.textViewDidChange?(self)
    }

    internal func setLinkIfNeeded() {
        let paraRange = (text as NSString).paragraphRange(for: selectedRange)
        (text as NSString).substring(with: paraRange)

    }

    private func registerUndoForCut(tuples: [(NSRange, NSAttributedString)]) {
//        let undoAttrString = attributedText.attributedSubstring(from: selectedRange)
        let reversedTuples = tuples.reversed()

        undoManager?.registerUndo(withTarget: self, handler: { (textView) in
            reversedTuples.forEach {
                let prevRange = NSRange(location: $0.0.location, length: 0)
                textView.textStorage.replaceCharacters(in: prevRange, with: $0.1)

            }
        })
    }

    private func registerUndo(attrString: NSAttributedString, selectedRange: NSRange) {
        let undoAttrString = attributedText.attributedSubstring(from: selectedRange)
        undoManager?.registerUndo(withTarget: self, handler: { (textView) in
            let prevRange = NSRange(location: selectedRange.location, length: attrString.length)
            textView.textStorage.replaceCharacters(in: prevRange, with: undoAttrString)

        })
    }

    private func scrollTo(range: NSRange) {
        if attributedText.length > 0 {
            let upperRange = NSRange(location: range.upperBound, length: 0)
            scrollRangeToVisible(upperRange)
        }
    }
}


extension TextView {
    internal func shouldReset(bullet: PianoBullet?, range: NSRange, replacementText text: String) -> Bool {
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
    
    internal func shouldDeleteBullet(bullet: PianoBullet?, range: NSRange) -> Bool {
        
        guard let uBullet = bullet,
            range.location + range.length
                == uBullet.baselineIndex else { return false }
        return true
        
    }
    
    internal func shouldAddBullet(bullet: PianoBullet?, range: NSRange) -> Bool {
        
        guard let uBullet = bullet,
            range.location + range.length
                > uBullet.baselineIndex else { return false }
        
        return true
    }
    
    internal func resetBullet(range: inout NSRange ,bullet: PianoBullet?) {
        
        guard let uBullet = bullet else { return }
        switch uBullet.isOrdered {
        case true:
            //문단 맨 앞에서부터 베이스라인까지 리셋해준다(패러그래프 스타일때문)
            let location = uBullet.paraRange.location
            let length = uBullet.baselineIndex - location
            let resetRange = NSMakeRange(location, length)
            textStorage.addAttributes(Preference.defaultAttr, range: resetRange)
            
        case false:
            textStorage.addAttributes(Preference.defaultAttr, range: uBullet.paraRange)
            //문단 맨 앞에서부터 베이스라인까지 리셋해준다(패러그래프 스타일때문)
            let attrString = NSAttributedString(string: uBullet.userDefineForm.shortcut, attributes: Preference.defaultAttr)
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
    
    internal func addBullet(range: inout NSRange, bullet: PianoBullet?) {
        
        guard let uBullet = bullet else { return }
        
        let addRange = NSMakeRange(
            uBullet.paraRange.location,
            uBullet.baselineIndex - uBullet.paraRange.location)
        let mutableAttrString = NSMutableAttributedString(attributedString: attributedText.attributedSubstring(from: addRange))
        
        
        switch uBullet.isOrdered {
        case true:
            let relativeNumRange = NSMakeRange(uBullet.range.location - addRange.location, uBullet.range.length)
            guard let number = UInt(uBullet.string) else { return }
            let nextNumberStr = String(number + 1)
            mutableAttrString.replaceCharacters(
                in: relativeNumRange,
                with: nextNumberStr)
            mutableAttrString.addAttributes(Preference.numAttr, range: relativeNumRange)
            let relativePunctuationRange = NSMakeRange(relativeNumRange.lowerBound + nextNumberStr.count, 1)
            mutableAttrString.addAttributes(Preference.punctuationAttr(num: nextNumberStr),range: relativePunctuationRange)
            
            
        case false:
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
    
    internal func deleteBullet(range: inout NSRange, bullet: PianoBullet?) {
        
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
    
    internal func adjust(range: inout NSRange, bullet: inout PianoBullet?) {
        
        guard let uBullet = bullet,
            let prevBullet = uBullet.prevBullet(text: self.text),
            let prevNumber = UInt(prevBullet.string),
            prevBullet.isOrdered,
            !prevBullet.isOverflow,
            uBullet.whitespaces.string == prevBullet.whitespaces.string,
            !prevBullet.isSequencial(next: uBullet) else { return }
        
        let numberString = "\(prevNumber + 1)"
        textStorage.replaceCharacters(in: uBullet.range, with: numberString)
        let changeInLength = numberString.count - uBullet.range.length
        
        
        selectedRange.location += changeInLength
        
        guard range.location > 0 else { return }
        if let adjustBullet = PianoBullet(type: .shortcut, text: self.text, selectedRange: NSMakeRange(range.location, 0)) {
            bullet = adjustBullet
        }
        
    }
    
    internal func transformTo(bullet: PianoBullet?) {
        
        guard let bullet = bullet, !bullet.isOverflow else { return }
        
        switch bullet.isOrdered {
        case true:
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
            
        case false:
            let value = bullet.value
            let attrString = NSAttributedString(string: value, attributes: Preference.formAttr(form: value))
            textStorage.replaceCharacters(in: bullet.range, with: attrString)
            let changeInLength = attrString.length - bullet.range.length
            selectedRange.location += changeInLength
            
        }
    }
    
    internal func adjustAfter(bullet: inout PianoBullet?) {
        
        guard var uBullet = bullet else {
            return
        }
        
        while uBullet.paraRange.location + uBullet.paraRange.length < attributedText.length {
            let range = NSMakeRange(uBullet.paraRange.location + uBullet.paraRange.length + 1, 0)
            
            guard let nextBullet = PianoBullet(type: .shortcut, text: self.text, selectedRange: range),
                let currentNum = UInt(uBullet.string),
                nextBullet.isOrdered,
                !nextBullet.isOverflow, uBullet.whitespaces.string == nextBullet.whitespaces.string,
                !uBullet.isSequencial(next: nextBullet) else { return }
            
            let nextNum = currentNum + 1
            textStorage.replaceCharacters(in: nextBullet.range, with: "\(nextNum)")
            
            bullet = nextBullet
            uBullet = nextBullet
            
            guard let adjustNextBullet = PianoBullet(type: .shortcut, text: self.text, selectedRange: range),
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

