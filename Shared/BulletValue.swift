////
////  BulletValue.swift
////  Emo
////
////  Created by Kevin Kim on 2018. 8. 23..
////  Copyright © 2018년 Piano. All rights reserved.
////
//
import Foundation

//TODO: Copy-on-Write 방식 책 보고 구현하기
public struct BulletValue {
    private let numRegex = "^\\s*(\\d+)(?=\\. )"
    private let emojiRegex = "^\\s*(\\S+)(?= )"

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

    private static func detectNum(text: String, searchRange: NSRange, regex: String) -> (String, NSRange, PianoBulletType)? {

        do {
            let regularExpression = try NSRegularExpression(pattern: regex, options: .anchorsMatchLines)
            guard let result = regularExpression.matches(in: text, options: .withTransparentBounds, range: searchRange).first else { return nil }
            let range = result.range(at: 1)
            let string = (text as NSString).substring(with: range)
            return (string, range, .orderedlist)
        } catch {
            print(error.localizedDescription)
        }
        return nil

    }

    private static func detectEmoji(text: String, searchRange: NSRange, regex: String) -> (String, NSRange, PianoBulletType)? {
        do {
            let regularExpression = try NSRegularExpression(pattern: regex, options: .anchorsMatchLines)
            guard let result = regularExpression.matches(in: text, options: .withTransparentBounds, range: searchRange).first else { return nil }
            let range = result.range(at: 1)
            let string = (text as NSString).substring(with: range)
            if string == Preference.checklistOffValue {
                return (string, range, .checklistOff)
            } else if string == Preference.checklistOnValue {
                return (string, range, .checklistOn)
            } else if string == Preference.firstlistValue {
                return (string, range, .firstlist)
            } else if string == Preference.secondlistValue {
                return (string, range, .secondlist)
            } else if string == Preference.idealistValue {
                return (string, range, .idealist)
            } else {
                return nil
            }
            
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }



    public init?(text: String, selectedRange: NSRange) {
        guard selectedRange.location != NSNotFound else { return nil }
        let nsText = text as NSString
        let paraRange = nsText.paragraphRange(for: selectedRange)

        if let (string, range, type) = BulletValue.detectNum(text: text, searchRange: paraRange, regex: numRegex) {
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

        if let (string, range, type) = BulletValue.detectEmoji(text: text, searchRange: paraRange, regex: emojiRegex) {
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

        return nil
    }

    //NSString용
    public init?(nsText: NSString, selectedRange: NSRange) {
        guard selectedRange.location != NSNotFound else { return nil }
        let paraRange = nsText.paragraphRange(for: selectedRange)
        let text = nsText as String

        if let (string, range, type) = BulletValue.detectNum(text: text, searchRange: paraRange, regex: numRegex) {
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

        if let (string, range, type) = BulletValue.detectEmoji(text: text, searchRange: paraRange, regex: emojiRegex) {
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

        return nil
    }

        /*
         피아노를 위한 line 이니셜라이져
         */
    public init?(text: String, lineRange: NSRange) {
        
        let nsText = text as NSString
        guard nsText.length != 0 else { return nil }
        let paraRange = nsText.paragraphRange(for: lineRange)
        
        if let (string, range, type) = BulletValue.detectNum(text: text, searchRange: lineRange, regex: numRegex) {
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
        
        if let (string, range, type) = BulletValue.detectEmoji(text: text, searchRange: lineRange, regex: emojiRegex) {
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

