//
//  HighlightKey.swift
//  Piano
//
//  Created by Kevin Kim on 29/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

public enum PianoHighlightType {
    case highlight
}

public struct HighlightKey {
    private let regexs: [(type: PianoHighlightType, regex: String)] = [
        (.highlight, "(::\\w+(\\s\\w+)*::)")
    ]
    
    public var type: PianoHighlightType
    public var string: String
    public var range: NSRange
    public let paraRange: NSRange
    public let text: String
    
    public var frontDoubleColonRange: NSRange {
        return NSMakeRange(range.lowerBound, 2)
    }
    
    public var endDoubleColonRange: NSRange {
        return NSMakeRange(range.upperBound - 2, 2)
    }
    
    public init?(text: String, selectedRange: NSRange) {
        let nsText = text as NSString
        let paraRange = nsText.paragraphRange(for: selectedRange)
        
        for (type, regex) in regexs {
            if let (string, range) = text.detect(searchRange: paraRange, regex: regex) {
                self.type = type
                self.text = text
                self.string = string
                self.range = range
                self.paraRange = paraRange
                return
            }
        }
        
        return nil
    }
    
}
