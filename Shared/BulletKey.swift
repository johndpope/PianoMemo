//
//  BulletKey.swift
//  Emo
//
//  Created by Kevin Kim on 2018. 8. 23..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
//
//protocol Bulletable {
//    var whitespaces: (string: String, range: NSRange) { get set }
//    var string: String { get set }
//    var range: NSRange { get set }
//    var type: PianoBulletType { get set }
//    var baselineIndex: Int { get }
//    var isOverflow: Bool { get }
//    var valueOff: String { get set }
//    var valueOn: String { get set }
//    var value: String { get }
//    var key: String { get }
//    var keyOff: String { get }
//    var keyOn: String { get }
//    func isSequencial(next: Bulletable) -> Bool
//    var followStr: String { get }
//    var rangeToRemove: NSRange { get }
//}
//
//public enum PianoBulletType {
//    case orderedlist
//    case unorderedlistOff
//    case unorderedlistOn
//}
//
////TODO: Copy-on-Write 방식 책 보고 구현하기
////TODO: key에 대한 고민
//public struct BulletKey: Bulletable {
//
//
//
////    (.orderedlist, "^\\s*(\\d+)(?=\\. )"),
////    (.unorderedListOff, "^\\s*([-])(?= )"),
////    (.unorderedListOn, "^\\s*([+])(?= )"),
////    (.unorderedListOff, "^\\s*([:])(?= )"),
////    (.unorderedListOn, "^\\s*([;])(?= )"),
////    (.firstlist, "^\\s*([-])(?= )"),
////    (.secondlist, "^\\s*([*])(?= )"),
////    (.checklistOn, "^\\s*([;；])(?= )"),
////    (.checklistOff, "^\\s*([:：])(?= )"),
////    (.idealist, "^\\s*([?])(?= )")
//
//    public var type: PianoBulletType
//    public var whitespaces: (string: String, range: NSRange)
//    public var string: String
//    public var range: NSRange
//    public let paraRange: NSRange
//    public let text: String
//    public var valueOn: String
//    public var valueOff: String
//    public var keyOff: String
//    public var keyOn: String
//
//    var followStr: String {
//        return self.type != .orderedlist ? " " : ". "
//    }
//
//    public var baselineIndex: Int {
//        return range.location + range.length + (type != .orderedlist ? 1 : 2)
//    }
//
//    public var value: String {
//        if string == keyOff {
//            return valueOff
//        } else {
//
//        }
//    }
//
//    public var isOverflow: Bool {
//        return range.length > 19
//    }
//
//    public var punctuationRange: NSRange {
//        return NSMakeRange(baselineIndex - 2, 1)
//    }
//
//    public var rangeToRemove: NSRange {
//        return NSMakeRange(0, baselineIndex)
//    }
//
//    public init?(text: String, selectedRange: NSRange) {
//        let nsText = text as NSString
//        let paraRange = nsText.paragraphRange(for: selectedRange)
//
//        for userDefineKey in Preference.userDefineForms {
//            if let (string, range) = text.detect(searchRange: paraRange, regex: userDefineKey.keyOffRegex) {
//                self.type = .unorderedlistOff
//                self.keyOff = userDefineKey.keyOff
//                self.keyOn = userDefineKey.keyOn
//                self.valueOff = userDefineKey.valueOff
//                self.valueOn = userDefineKey.valueOn
//                self.text = text
//                self.string = string
//                self.range = range
//                let wsRange = NSMakeRange(paraRange.location, range.location - paraRange.location)
//                let wsString = nsText.substring(with: wsRange)
//                self.whitespaces = (wsString, wsRange)
//                self.paraRange = paraRange
//                return
//            }
//
//            if let (string, range) = text.detect(searchRange: paraRange, regex: userDefineKey.keyOnRegex) {
//                self.type = .unorderedlistOn
//                self.keyOff = userDefineKey.keyOff
//                self.keyOn = userDefineKey.keyOn
//                self.valueOff = userDefineKey.valueOff
//                self.valueOn = userDefineKey.valueOn
//                self.text = text
//                self.string = string
//                self.range = range
//                let wsRange = NSMakeRange(paraRange.location, range.location - paraRange.location)
//                let wsString = nsText.substring(with: wsRange)
//                self.whitespaces = (wsString, wsRange)
//                self.paraRange = paraRange
//                return
//            }
//        }
//
//        if let (string, range) = text.detect(searchRange: paraRange, regex: "^\\s*(\\d+)(?=\\. )") {
//            self.type = .orderedlist
//            self.keyOff = string
//            self.keyOn = string
//            self.valueOff = string
//            self.valueOn = string
//            self.text = text
//            self.string = string
//            self.range = range
//            let wsRange = NSMakeRange(paraRange.location, range.location - paraRange.location)
//            let wsString = nsText.substring(with: wsRange)
//            self.whitespaces = (wsString, wsRange)
//            self.paraRange = paraRange
//            return
//        }
//
//        return nil
//    }
//
//    public func prevBullet(text: String) -> BulletKey? {
//
//        guard paraRange.location != 0 else { return nil }
//        return BulletKey(text: text, selectedRange: NSMakeRange(paraRange.location - 1, 0))
//
//    }
//
//    func isSequencial(next: Bulletable) -> Bool {
//
//        guard let current = UInt(string),
//            let next = UInt(next.string) else { return false }
//        return current + 1 == next
//
//    }
//
//    func paraStyleForPDF() -> ParagraphStyle {
//        let mutableParaStyle = FormAttribute.defaultParaStyleForPDF
//        let attrStr = NSAttributedString(string: whitespaces.string + value + followStr, attributes: FormAttribute.defaultAttrForPDF)
//        mutableParaStyle.headIndent = attrStr.size().width
//        return mutableParaStyle
//    }
//
//}
//
