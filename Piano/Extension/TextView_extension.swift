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
        let newSelectedRange = NSMakeRange(range.location + attrString.length, 0)
        selectedRange = newSelectedRange
        scrollTo(range: newSelectedRange)
        //중간에서 붙여넣기 했는데 이게 되면 안된다
        //        scrollToBottom()
    }
    
    
    
    
    
//    internal func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {
//        selectedRange = range
//        registerUndo(attrString: attrString, selectedRange: range)
//        textStorage.replaceCharacters(in: range, with: attrString)
//        delegate?.textViewDidChange?(self)
//        selectedRange.location += attrString.length
//        selectedRange.length = 0
//        //중간에서 붙여넣기 했는데 이게 되면 안된다
////        scrollToBottom()
//    }
    
    internal func replaceHighlightedTextToEmpty() {
        var highlightedRanges: [NSRange] = []
        attributedText.enumerateAttribute(.backgroundColor, in: NSMakeRange(0, attributedText.length), options: .reverse) { (value, range, _) in
            guard let color = value as? Color, color == Color.highlight else { return }
            highlightedRanges.append(range)
        }
        
        highlightedRanges.forEach {
            textStorage.addAttributes([.backgroundColor : Color.clear], range: $0)
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
                let prevRange = NSMakeRange($0.0.location, 0)
                textView.textStorage.replaceCharacters(in: prevRange, with: $0.1)
            }
        })
    }
    
    private func registerUndo(attrString: NSAttributedString, selectedRange: NSRange) {
        let undoAttrString = attributedText.attributedSubstring(from: selectedRange)
        undoManager?.registerUndo(withTarget: self, handler: { (textView) in
            let prevRange = NSMakeRange(selectedRange.location, attrString.length)
            textView.textStorage.replaceCharacters(in: prevRange, with: undoAttrString)
        })
    }
    
    private func scrollTo(range: NSRange) {
        if attributedText.length > 0 {
            let upperRange = NSMakeRange(range.upperBound, 0)
            scrollRangeToVisible(upperRange)
        }
    }
}

