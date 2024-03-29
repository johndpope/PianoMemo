//
//  PianoBullet.swift
//  Piano
//
//  Created by Kevin Kim on 09/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

struct UserDefineForm: Codable {
    var shortcut: String
    let keyOn: String
    let keyOff: String
    var valueOn: String
    var valueOff: String

    struct ValueRegex {
        let regex: String
        let string: String
    }

    init(shortcut: String, keyOn: String, keyOff: String, valueOn: String, valueOff: String) {
        self.shortcut = shortcut
        self.keyOn = keyOn
        self.keyOff = keyOff
        self.valueOn = valueOn
        self.valueOff = valueOff
    }

    var shortcutRegex: String {
        return "^\\s*([\(shortcut)])(?= )"
    }

    var keyOnRegex: String {
        return "^\\s*([\(keyOn)])(?= )"
    }

    var keyOffRegex: String {
        return "^\\s*([\(keyOff)])(?= )"
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
        case shortcut
    }

    let type: BulletType
    let isOn: Bool
    let whitespaces: (string: String, range: NSRange)
    let string: String
    let range: NSRange
    let paraRange: NSRange
    var value: String
    let key: String

    let userDefineForm: UserDefineForm

    let isOrdered: Bool
    let numRegex = "^\\s*(\\d+)(?=\\. )"

    //배열로 만들어 놓고, 보상 갯수에 따라, 루프를 돌기
    static let oldKeyOffList = [":", "-", "*", "?", "✺"]
    static let oldKeyOnList = [";", "♪", "♫", "♬", "♭"]

    static let keyOffList = ["✷", "✵", "✸", "✹", "✺"]
    static let keyOnList = ["♩", "♪", "♫", "♬", "♭"]
    static let shortcutList = ["-", "*", ":", "+", "!"]
    static let valueOffList = ["🙅‍♀️", "🍋", "🍏", "🍓", "🐣"]
    static let valueOnList = ["🙆‍♀️", "🍉", "🍎", "🍇", "🐥"]

    static let keyValueStore = NSUbiquitousKeyValueStore.default

    static var userDefineForms: [UserDefineForm] {
        get {
            if let forms = keyValueStore.data(forKey: UserDefaultsKey.userDefineForms) {
                do {
                    let array = try PropertyListDecoder().decode(Array<UserDefineForm>.self, from: forms)
                    return array
                } catch {
                    print("userDefineForms 가져오려다 실패1: \(error.localizedDescription)")
                    keyValueStore.removeObject(forKey: UserDefaultsKey.userDefineForms)
                    let userDefineForms: [UserDefineForm] = [UserDefineForm(shortcut: shortcutList[0], keyOn: keyOnList[0], keyOff: keyOffList[0], valueOn: valueOnList[0], valueOff: valueOffList[0])]

                    do {
                        keyValueStore.set(try PropertyListEncoder().encode(userDefineForms), forKey: UserDefaultsKey.userDefineForms)
                    } catch {
                        print("userDefineForms 가져오려다 실패2: \(error.localizedDescription)")
                    }

                    return userDefineForms
                }
            } else {
                let userDefineForms: [UserDefineForm] = [UserDefineForm(shortcut: shortcutList[0], keyOn: keyOnList[0], keyOff: keyOffList[0], valueOn: valueOnList[0], valueOff: valueOffList[0])]
                do {
                    keyValueStore.set(try PropertyListEncoder().encode(userDefineForms), forKey: UserDefaultsKey.userDefineForms)
                } catch {
                    print("userDefineForms 가져오려다 실패2: \(error.localizedDescription)")
                }

                return userDefineForms
            }
        } set {
            do {
                keyValueStore.set(try PropertyListEncoder().encode(newValue), forKey: UserDefaultsKey.userDefineForms)
            } catch {
                print("userDefineForms 저장하다 실패: \(error.localizedDescription)")
            }

        }
    }

    init?(type: BulletType, text: String, selectedRange: NSRange) {
        let nsText = text as NSString
        let paraRange = nsText.paragraphRange(for: selectedRange)

        if let (string, range) = text.detect(searchRange: paraRange, regex: numRegex) {
            self.string = string
            self.range = range
            self.isOn = false
            self.type = .shortcut
            self.isOrdered = true
            let wsRange = NSRange(location: paraRange.location, length: range.location - paraRange.location)
            let wsString = nsText.substring(with: wsRange)
            self.whitespaces = (wsString, wsRange)
            self.paraRange = paraRange
            self.key = string
            self.value = string
            self.userDefineForm = UserDefineForm(shortcut: string, keyOn: string, keyOff: string, valueOn: string, valueOff: string)
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
                    let wsRange = NSRange(location: paraRange.location, length: range.location - paraRange.location)
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
                    let wsRange = NSRange(location: paraRange.location, length: range.location - paraRange.location)
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
                    let wsRange = NSRange(location: paraRange.location, length: range.location - paraRange.location)
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
                    let wsRange = NSRange(location: paraRange.location, length: range.location - paraRange.location)
                    let wsString = nsText.substring(with: wsRange)
                    self.whitespaces = (wsString, wsRange)
                    self.paraRange = paraRange
                    self.key = userDefineForm.keyOn
                    self.value = userDefineForm.valueOn
                    self.userDefineForm = userDefineForm
                    return
                }
            }

        case .shortcut:
            for userDefineForm in PianoBullet.userDefineForms {
                if let (string, range) = text.detect(searchRange: paraRange, regex: userDefineForm.shortcutRegex) {
                    self.string = string
                    self.range = range
                    self.isOn = false
                    self.type = .shortcut
                    self.isOrdered = false
                    let wsRange = NSRange(location: paraRange.location, length: range.location - paraRange.location)
                    let wsString = nsText.substring(with: wsRange)
                    self.whitespaces = (wsString, wsRange)
                    self.paraRange = paraRange
                    self.key = userDefineForm.keyOff
                    self.value = userDefineForm.valueOff
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
        return range.location + range.length + (isOrdered ? 2 : 1)
    }

    public var isOverflow: Bool {
        return range.length > 19
    }

    public var punctuationRange: NSRange {
        return NSRange(location: baselineIndex - 2, length: 1)
    }

    public var rangeToRemove: NSRange {
        return NSRange(location: 0, length: baselineIndex)
    }

    public func prevBullet(text: String) -> PianoBullet? {

        guard paraRange.location != 0 else { return nil }
        return PianoBullet(type: .key, text: text, selectedRange: NSRange(location: paraRange.location - 1, length: 0))
    }

    func isSequencial(next: PianoBullet) -> Bool {

        guard let current = UInt(value),
            let next = UInt(next.value) else { return false }
        return current + 1 == next

    }

    func paraStyleForPDF() -> ParagraphStyle {
        let mutableParaStyle = FormAttribute.defaultParaStyleForPDF
        let attrStr = NSAttributedString(string: whitespaces.string + value + followStr, attributes: FormAttribute.defaultAttrForPDF)
        mutableParaStyle.headIndent = attrStr.size().width
        return mutableParaStyle
    }

}
