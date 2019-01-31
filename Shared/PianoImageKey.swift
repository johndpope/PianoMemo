//
//  ImageKey.swift
//  Piano
//
//  Created by Kevin Kim on 31/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

struct PianoImageKey {
    
    enum PianoImageType {
        case image
        case imageSelection
    }
    
    private let regexs: [(type: PianoImageType, regex: String)] = [
        (.image, "^!\\[[^\\]]*\\]\\(image:([^\\)]+)"),
         (.imageSelection, "^!\\[[^\\]]*\\]\\(image:(//)\\)")]
    
    
    public var type: PianoImageType
    public var string: String
    public var range: NSRange
    public let paraRange: NSRange
    public let text: String
    
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
