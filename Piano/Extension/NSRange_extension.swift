//
//  NSRange_extension.swift
//  Block
//
//  Created by Kevin Kim on 2018. 8. 9..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

extension NSRange {
    internal func move(offset: Int) -> NSRange {
        return NSMakeRange(self.location + offset, self.length)
    }
}

extension NSRange {
    func toTextRange(textInput:UITextInput) -> UITextRange? {
        if let rangeStart = textInput.position(from: textInput.beginningOfDocument, offset: location),
            let rangeEnd = textInput.position(from: rangeStart, offset: length) {
            return textInput.textRange(from: rangeStart, to: rangeEnd)
        }
        return nil
    }
}
