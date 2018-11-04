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

protocol Bulletable {
    var whitespaces: (string: String, range: NSRange) { get set }
    var string: String { get set }
    var range: NSRange { get set }
    var type: PianoBulletType { get set }
    var baselineIndex: Int { get }
    var isOverflow: Bool { get }
    var value: String { get }
    var key: String { get }
    func isSequencial(next: Bulletable) -> Bool
    var followStr: String { get }
    var rangeToRemove: NSRange { get }
}

//TODO: Copy-on-Write 방식 책 보고 구현하기
public struct BulletKey: Bulletable {
    
    private let regexs: [(type: PianoBulletType, regex: String)] = [
        (.orderedlist, "^\\s*(\\d+)(?=\\. )"),
        (.firstlist, "^\\s*([-])(?= )"),
        (.secondlist, "^\\s*([*])(?= )"),
        (.checklistOn, "^\\s*([;；])(?= )"),
        (.checklistOff, "^\\s*([:：])(?= )"),
        (.idealist, "^\\s*([?])(?= )")
    ]
    
    public var type: PianoBulletType
    public var whitespaces: (string: String, range: NSRange)
    public var string: String
    public var range: NSRange
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
    
    public var key: String {
        switch type {
        case .orderedlist:
            return (text as NSString).substring(with: range)
        case .checklistOff:
            return Preference.checklistOffKey
        case .checklistOn:
            return Preference.checklistOnKey
        case .firstlist:
            return Preference.firstlistKey
        case .secondlist:
            return Preference.secondlistKey
        case .idealist:
            return Preference.idealistKey
        }
    }
    
    var followStr: String {
        return self.type != .orderedlist ? " " : ". "
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
    
    public var rangeToRemove: NSRange {
        return NSMakeRange(0, baselineIndex)
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
    
    func isSequencial(next: Bulletable) -> Bool {
        
        guard let current = UInt(string),
            let next = UInt(next.string) else { return false }
        return current + 1 == next
        
    }
    
    func paraStyleForPDF() -> ParagraphStyle {
        let mutableParaStyle = FormAttribute.defaultParaStyleForPDF
        let attrStr = NSAttributedString(string: whitespaces.string + value + followStr, attributes: FormAttribute.defaultAttrForPDF)
        mutableParaStyle.headIndent = attrStr.size().width
        return mutableParaStyle
    }
    
}

