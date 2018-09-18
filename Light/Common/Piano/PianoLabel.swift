//
//  PianoLabel.swift
//  Piano
//
//  Created by Kevin Kim on 2018. 6. 1..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreGraphics

struct PianoData {
    let charRect: CGRect
    let charRange: NSRange
    let charOriginCenter: CGPoint
    let charText: String
    var charAttrs: [NSAttributedString.Key : Any]
    
    init(charRect: CGRect, charRange: NSRange, charOriginCenter: CGPoint, charText: String, charAttrs: [NSAttributedString.Key : Any] ) {
        self.charRect = charRect
        self.charRange = charRange
        self.charOriginCenter = charOriginCenter
        self.charText = charText
        self.charAttrs = charAttrs
    }
}

class PianoLabel: Label {
    
    var data: PianoData? {
        didSet {
            guard let data = self.data else { return }
            frame = data.charRect
//            var attrs = data.characterAttrs
//            let mutableParagraphStyle = MutableParagraphStyle()
//            mutableParagraphStyle.lineSpacing = LocalPreference.lineSpacing
//            attrs[.paragraphStyle] = mutableParagraphStyle
//            attrs[.baselineOffset] = Preference.lineSpacing / 2
            
            attributedText = NSAttributedString(string: data.charText, attributes: data.charAttrs)
        }
    }
}
