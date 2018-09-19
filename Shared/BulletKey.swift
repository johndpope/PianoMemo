//
//  BulletKey.swift
//  Emo
//
//  Created by Kevin Kim on 2018. 8. 23..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation

public enum PianoBulletType {
    case orderedlist
    case firstlist
    case secondlist
    case checklistOn
    case checklistOff
    case idealist
}

//TODO: Copy-on-Write 방식 책 보고 구현하기
public struct BulletKey {
    
    private let regexs: [(type: PianoBulletType, regex: String)] = [
        (.orderedlist, "^\\s*(\\d+)(?=\\. )"),
        (.firstlist, "^\\s*([-])(?= )"),
        (.secondlist, "^\\s*([*])(?= )"),
        (.checklistOn, "^\\s*([;])(?= )"),
        (.checklistOff, "^\\s*([:])(?= )"),
        (.idealist, "^\\s*([?])(?= )")
    ]
    
    public let type: PianoBulletType
    public let whitespaces: (string: String, range: NSRange)
    public var string: String
    public let range: NSRange
    public let paraRange: NSRange
    public let text: String
    
    public var value: String {
        switch type {
        case .orderedlist:
            return string
        case .checklistOn:
            return Preference.checklistOnValue
        case .checklistOff:
            return Preference.checklistOffValue
        case .firstlist:
            return Preference.firstlistValue
        case .secondlist:
            return Preference.secondlistValue
        case .idealist:
            return Preference.idealistValue
        }
    }
    
    public var paragraphStyle: MutableParagraphStyle {
        let paragraphStyle = MutableParagraphStyle()
        
        let attrString = NSAttributedString(string: whitespaces.string + value + " ",
                                            attributes: [.font: Preference.defaultFont])
        paragraphStyle.headIndent = attrString.size().width + Preference.kern(form: value)
        return paragraphStyle
    }
    
    
    public var baselineIndex: Int {
        return range.location + range.length + (type != .orderedlist ? 1 : 2)
    }
    
    public var isOverflow: Bool {
        return range.length > 19
    }
    
    public var punctuationRange: NSRange {
        return NSMakeRange(baselineIndex - 2, 1)
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
                let wsRange = NSMakeRange(paraRange.location, range.location - paraRange.location)
                let wsString = nsText.substring(with: wsRange)
                self.whitespaces = (wsString, wsRange)
                self.paraRange = paraRange
                return
            }
        }
        
        return nil
    }
    
    /*
     피아노를 위한 line 이니셜라이져
     */
    public init?(text: String, lineRange: NSRange) {
        
        let nsText = text as NSString
        guard nsText.length != 0 else { return nil }
        let paraRange = nsText.paragraphRange(for: lineRange)
        for (type, regex) in regexs {
            if let (string, range) = text.detect(searchRange: lineRange, regex: regex) {
                self.type = type
                self.text = text
                self.string = string
                self.range = range
                let wsRange = NSMakeRange(paraRange.location, range.location - paraRange.location)
                let wsString = nsText.substring(with: wsRange)
                self.whitespaces = (wsString, wsRange)
                self.paraRange = paraRange
                return
            }
        }
        
        return nil
    }
    
    public func prevBullet(text: String) -> BulletKey? {
        
        guard paraRange.location != 0 else { return nil }
        return BulletKey(text: text, selectedRange: NSMakeRange(paraRange.location - 1, 0))
        
    }
    
    public func isSequencial(next: BulletKey) -> Bool {
        
        guard let current = UInt(string),
            let next = UInt(next.string) else { return false }
        return current + 1 == next
        
    }
    
}

