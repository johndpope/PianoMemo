//
//  PianoBullet.swift
//  Piano
//
//  Created by Kevin Kim on 09/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

struct UserDefineForm {
    let keyOn: String
    let keyOff: String
    let valueOn: String
    let valueOff: String
    
    var keyOnRegex: String {
        return "^\\s*([\(keyOn)])(?= )"
    }
    
    var keyOffRegex: String {
        return "^\\s*([\(keyOff)])(?= )"
    }
    
    struct ValueRegex {
        let regex: String
        let string: String
    }
    
    var valueOffRegex: ValueRegex {
        return ValueRegex(regex: "^\\s*(\\S+)(?= )", string: valueOff)
    }
    
    var valueOnRegex: ValueRegex {
        return ValueRegex(regex: "^\\s*(\\S+)(?= )", string: valueOn)
    }
}



public struct PianoBullet {
    enum BulletType {
        case key
        case value
    }
    
    let type: BulletType
    let isOn: Bool
    let whitespaces: (string: String, range: NSRange)
    var string: String
    let range: NSRange
    let paraRange: NSRange
    let value: String
    let key: String
    
    let userDefineForm: UserDefineForm
    
    let isOrdered: Bool
    let numRegex = "^\\s*(\\d+)(?=\\. )"
    
    static let userDefineForms: [UserDefineForm] = [
        UserDefineForm(keyOn: "✷", keyOff: "ㅁ", valueOn: "🥰", valueOff: "😀"),
        UserDefineForm(keyOn: "✵", keyOff: "ㄴ", valueOn: "🤬", valueOff: "🥵"),
        UserDefineForm(keyOn: "✹", keyOff: "ㅇ", valueOn: "☠️", valueOff: "💀"),
        UserDefineForm(keyOn: "✺", keyOff: "ㄹ", valueOn: "👻", valueOff: "💩")
    ]
    
    init?(type: BulletType, text: String, selectedRange: NSRange) {
        let nsText = text as NSString
        let paraRange = nsText.paragraphRange(for: selectedRange)
        
        if let (string, range) = text.detect(searchRange: paraRange, regex: numRegex) {
            self.string = string
            self.range = range
            self.isOn = false
            self.type = .key
            self.isOrdered = true
            let wsRange = NSMakeRange(paraRange.location, range.location - paraRange.location)
            let wsString = nsText.substring(with: wsRange)
            self.whitespaces = (wsString, wsRange)
            self.paraRange = paraRange
            self.key = string
            self.value = string
            self.userDefineForm = UserDefineForm(keyOn: string, keyOff: string, valueOn: string, valueOff: string)
            return
        }
        
        switch type {
        case .key:
            for userDefineForm in PianoBullet.userDefineForms {
                if let (string, range) = text.detect(searchRange: paraRange, regex: userDefineForm.keyOffRegex) {
                    self.string = string
                    self.range = range
                    self.isOn = false
                    self.type = .key
                    self.isOrdered = false
                    let wsRange = NSMakeRange(paraRange.location, range.location - paraRange.location)
                    let wsString = nsText.substring(with: wsRange)
                    self.whitespaces = (wsString, wsRange)
                    self.paraRange = paraRange
                    self.key = userDefineForm.keyOff
                    self.value = userDefineForm.valueOff
                    self.userDefineForm = userDefineForm
                    return
                }
                
                if let (string, range) = text.detect(searchRange: paraRange, regex: userDefineForm.keyOnRegex) {
                    self.string = string
                    self.range = range
                    self.isOn = true
                    self.type = .key
                    self.isOrdered = false
                    let wsRange = NSMakeRange(paraRange.location, range.location - paraRange.location)
                    let wsString = nsText.substring(with: wsRange)
                    self.whitespaces = (wsString, wsRange)
                    self.paraRange = paraRange
                    self.key = userDefineForm.keyOn
                    self.value = userDefineForm.valueOn
                    self.userDefineForm = userDefineForm
                    return
                }
            }
            
        case .value:
            for userDefineForm in PianoBullet.userDefineForms {
                
                if let (string, range) = text.detect(searchRange: paraRange, valueRegex: userDefineForm.valueOffRegex) {
                    self.string = string
                    self.range = range
                    self.isOn = false
                    self.type = .value
                    self.isOrdered = false
                    let wsRange = NSMakeRange(paraRange.location, range.location - paraRange.location)
                    let wsString = nsText.substring(with: wsRange)
                    self.whitespaces = (wsString, wsRange)
                    self.paraRange = paraRange
                    self.key = userDefineForm.keyOff
                    self.value = userDefineForm.valueOff
                    self.userDefineForm = userDefineForm
                    return
                }
                
                if let (string, range) = text.detect(searchRange: paraRange, valueRegex: userDefineForm.valueOnRegex) {
                    self.string = string
                    self.range = range
                    self.isOn = true
                    self.type = .value
                    self.isOrdered = false
                    let wsRange = NSMakeRange(paraRange.location, range.location - paraRange.location)
                    let wsString = nsText.substring(with: wsRange)
                    self.whitespaces = (wsString, wsRange)
                    self.paraRange = paraRange
                    self.key = userDefineForm.keyOn
                    self.value = userDefineForm.valueOn
                    self.userDefineForm = userDefineForm
                    return
                }
            }
        }
        
        return nil
    }
    
    
    var followStr: String {
        return Int(string) != nil ? ". " : " "
    }
    
    public var baselineIndex: Int {
        return range.location + range.length + (Int(string) != nil ? 2 : 1)
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
    
    public func prevBullet(text: String) -> PianoBullet? {
        
        guard paraRange.location != 0 else { return nil }
        return PianoBullet(type: .key, text: text, selectedRange: NSMakeRange(paraRange.location - 1, 0))
    }
    
    func isSequencial(next: PianoBullet) -> Bool {
        
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
