//
//  ImageKey.swift
//  Piano
//
//  Created by Kevin Kim on 31/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

struct PianoImageKey {
    enum PianoImageValueType {
        case imageValue
        case imagePickerValue
    }
    
    enum PianoImageType {
        case shortcut
        case value(PianoImageValueType)
        
        var shortcut: String { return "@" }
        
        var regex: String {
            switch self {
            case .shortcut:
                return "^([\(shortcut)])(?= )"
            case .value(let detailType):
                switch detailType {
                case .imageValue:
                    return "^!\\[[^\\]]*\\]\\(image:([^\\)]+)"
                case .imagePickerValue:
                    return "^!\\[[^\\]]*\\]\\(image:(//)\\)"
                }
            }
        }
    }
    
    public var type: PianoImageType
    public var string: String
    public var range: NSRange
    public let paraRange: NSRange
    public let text: String
    
    init?(type: PianoImageType, text: String, selectedRange: NSRange) {
        let nsText = text as NSString
        let paraRange = nsText.paragraphRange(for: selectedRange)
        
        if let (string, range) = text.detect(searchRange: paraRange, regex: type.regex) {
            self.type = type
            self.string = string
            self.range = range
            self.paraRange = paraRange
            self.text = text
            return
        }
        return nil
    }
}
