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
    let characterRect: CGRect
    let characterRange: NSRange
    let characterOriginCenter: CGPoint
    let characterText: String
    var characterAttrs: [NSAttributedStringKey : Any]
}

class PianoLabel: Label {
    
    var data: PianoData? {
        didSet {
            guard let data = self.data else { return }
            frame = data.characterRect
//            var attrs = data.characterAttrs
//            let mutableParagraphStyle = MutableParagraphStyle()
//            mutableParagraphStyle.lineSpacing = Preference.lineSpacing
//            attrs[.paragraphStyle] = mutableParagraphStyle
//            attrs[.baselineOffset] = Preference.lineSpacing / 2
            
            attributedText = NSAttributedString(string: data.characterText, attributes: data.characterAttrs)
        }
    }
}
