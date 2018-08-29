//
//  BulletValue.swift
//  Emo
//
//  Created by Kevin Kim on 2018. 8. 23..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation

public enum PianoBulletType {
    case orderedlist
    case unOrderedlist
    case checklist
    case idealist
}
//TODO: Copy-on-Write 방식 책 보고 구현하기
public struct BulletValue {
    
    
//    private let regexs: [(type: PianoBulletType, regex: String)] = [
//        (.orderedlist, "^\\s*(\\d+)(?=\\. )"),
//        (.unOrderedlist, "^\\s*([●])(?= )"),
//        (.checklist, "^\\s*([-])(?= )"),
//        (.idealist, "^\\s*([?])(?= )")
//    ]
    private let regexs: [String] = [
        "^\\s*(\\d+)(?=\\. )",
        "^\\s*(\\S+)(?= )"
    ]
    
    public let type: PianoBulletType
    public let whitespaces: (string: String, range: NSRange)
    public var string: String
    public let range: NSRange
    public let paraRange: NSRange
    public let text: String
    
    public var key: String {
        switch type {
        case .orderedlist:
            return (text as NSString).substring(with: range)
        case .checklist:
            return Preference.checklistKey
        case .unOrderedlist:
            return Preference.unorderedlistKey
        case .idealist:
            return Preference.idealistKey
        }
    }
    
    
    public var baselineIndex: Int {
        return range.location + range.length + (type != .orderedlist ? 1 : 2)
    }
    
    public var isOverflow: Bool {
        return range.length > 19
    }
    
    public var paragraphStyle: MutableParagraphStyle {
        let paragraphStyle = MutableParagraphStyle()
        
        let attrString = NSAttributedString(string: whitespaces.string + string + " ",
                                            attributes: [.font: Preference.defaultFont])
        paragraphStyle.headIndent = attrString.size().width + Preference.kern(form: string)
        return paragraphStyle
    }
    
    private static func detect(text: String, searchRange: NSRange, regex: String) -> (String, NSRange, PianoBulletType)? {
        do {
            let regularExpression = try NSRegularExpression(pattern: regex, options: .anchorsMatchLines)
            guard let result = regularExpression.matches(in: text, options: .withTransparentBounds, range: searchRange).first else { return nil }
            let range = result.range(at: 1)
            let string = (text as NSString).substring(with: range)
            if UInt(string) != nil {
                return (string, range, .orderedlist)
            } else if string == Preference.checkOffValue || string == Preference.checkOnValue {
                return (string, range, .checklist)
            } else if string == Preference.idealistValue {
                return (string, range, .idealist)
            } else if string == Preference.unOrderedlistValue {
                return (string, range, .unOrderedlist)
            } else {
                return nil
            }
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    
    
    public init?(text: String, selectedRange: NSRange) {
        let nsText = text as NSString
        let paraRange = nsText.paragraphRange(for: selectedRange)
        
        
        for regex in regexs {
            if let (string, range, type) = BulletValue.detect(text: text, searchRange: paraRange, regex: regex) {
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
    
    //NSString용
    public init?(nsText: NSString, selectedRange: NSRange) {
        let paraRange = nsText.paragraphRange(for: selectedRange)
        let text = nsText as String
        for regex in regexs {
            if let (string, range, type) = BulletValue.detect(text: text, searchRange: paraRange, regex: regex) {
                self.type = type
                self.text = text as String
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
        for regex in regexs {
            if let (string, range, type) = BulletValue.detect(text: text, searchRange: lineRange, regex: regex) {
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
