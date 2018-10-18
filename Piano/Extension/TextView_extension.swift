//
//  TextView_extension.swift
//  Piano
//
//  Created by Kevin Kim on 18/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

extension TextView {
    private func registerUndo(attrString: NSAttributedString, selectedRange: NSRange) {
        let undoAttrString = attributedText.attributedSubstring(from: selectedRange)
        undoManager?.registerUndo(withTarget: self, handler: { (textView) in
            let prevRange = NSMakeRange(selectedRange.location, attrString.length)
            textView.textStorage.replaceCharacters(in: prevRange, with: undoAttrString)
        })
        
    }
    
    private func scrollToBottom() {
        if attributedText.length > 0 {
            let location = attributedText.length - 1
            let bottom = NSMakeRange(location, 1)
            scrollRangeToVisible(bottom)
        }
    }
    
    /**
     역할
     1. undo 등록
     2. 글자 대체
     3. 델리게이트 노티
     4. selectedRange변경
     5. 아래로 스크롤
     */
    internal func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {
        selectedRange = range
        registerUndo(attrString: attrString, selectedRange: range)
        textStorage.replaceCharacters(in: range, with: attrString)
        delegate?.textViewDidChange?(self)
        selectedRange.location += attrString.length
        selectedRange.length = 0
        scrollToBottom()
    }
    
    
}
