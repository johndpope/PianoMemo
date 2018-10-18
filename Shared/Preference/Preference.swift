//
//  LocalPreference.swift
//  Emo
//
//  Created by Kevin Kim on 2018. 8. 22..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreGraphics

#if os(iOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

struct Preference {    
    #if os(iOS)
    internal static let textColor: Color = Color.darkText
    internal static let defaultFont = Font.preferredFont(forTextStyle: .body)
    #elseif os(OSX)

    internal static let textColor: Color = NSColor.darkGray
    internal static let defaultFont = NSFont.systemFont(ofSize: 40, weight: .light)

    #endif
//Color(hex6: "FF2D55")
    internal static let effectColor: Color = Color.point
    internal static let punctuationColor: Color = Color.lightGray
    internal static let strikeThroughColor: Color = Color.lightGray

    internal static var gender: String {
        get {
            if let value = UserDefaults.standard.value(forKey: UserDefaultsKey.gender) as? String {
                return value
            } else {
                UserDefaults.standard.setValue("👧", forKey: UserDefaultsKey.gender)
                return UserDefaults.standard.value(forKey: UserDefaultsKey.gender) as! String
            }
        } set {
            UserDefaults.standard.setValue(newValue, forKey: UserDefaultsKey.gender)
        }
    }
    
    internal static var allKeys: [String] = [Preference.idealistKey, Preference.firstlistKey, Preference.secondlistKey, Preference.checklistOnKey, Preference.checklistOffKey, Preference.checklistOnChinaKey, Preference.checklistOffChinaKey]
    
    internal static var checklistOnKey = ";"
    internal static var checklistOnChinaKey = "；"
    internal static var checklistOnValue: String {
        get {
            if let value = UserDefaults.standard.value(forKey: UserDefaultsKey.checklistOnValue) as? String {
                return value
            } else {
                UserDefaults.standard.setValue("🙆‍♀️", forKey: UserDefaultsKey.checklistOnValue)
                return UserDefaults.standard.value(forKey: UserDefaultsKey.checklistOnValue) as! String
            }
        } set {
            UserDefaults.standard.setValue(newValue, forKey: UserDefaultsKey.checklistOnValue)
        }
    }
    
    internal static let checklistOffKey = ":"
    internal static let checklistOffChinaKey = "："
    internal static var checklistOffValue: String {
        get {
            if let value = UserDefaults.standard.value(forKey: UserDefaultsKey.checklistOffValue) as? String {
                return value
            } else {
                UserDefaults.standard.setValue("🙅‍♀️", forKey: UserDefaultsKey.checklistOffValue)
                return UserDefaults.standard.value(forKey: UserDefaultsKey.checklistOffValue) as! String
            }
        } set {
            UserDefaults.standard.setValue(newValue, forKey: UserDefaultsKey.checklistOffValue)
        }
    }
    
    internal static let idealistKey = "?"
    internal static var idealistValue: String {
        get {
            if let value = UserDefaults.standard.value(forKey: UserDefaultsKey.idealistValue) as? String {
                return value
            } else {
                UserDefaults.standard.setValue("💡", forKey: UserDefaultsKey.idealistValue)
                return UserDefaults.standard.value(forKey: UserDefaultsKey.idealistValue) as! String
            }
        } set {
            UserDefaults.standard.setValue(newValue, forKey: UserDefaultsKey.idealistValue)
        }
    }
    
    internal static let firstlistKey = "-"
    internal static var firstlistValue: String {
        get {
            if let value = UserDefaults.standard.value(forKey: UserDefaultsKey.firstlistValue) as? String {
                return value
            } else {
                UserDefaults.standard.setValue("🐶", forKey: UserDefaultsKey.firstlistValue)
                return UserDefaults.standard.value(forKey: UserDefaultsKey.firstlistValue) as! String
            }
        } set {
            UserDefaults.standard.setValue(newValue, forKey: UserDefaultsKey.firstlistValue)
        }
    }
    
    internal static let secondlistKey = "*"
    internal static var secondlistValue: String {
        get {
            if let value = UserDefaults.standard.value(forKey: UserDefaultsKey.secondlistValue) as? String {
                return value
            } else {
                UserDefaults.standard.setValue("🍏", forKey: UserDefaultsKey.secondlistValue)
                return UserDefaults.standard.value(forKey: UserDefaultsKey.secondlistValue) as! String
            }
        } set {
            UserDefaults.standard.setValue(newValue, forKey: UserDefaultsKey.secondlistValue)
        }
    }
    
    internal static var emojiTags: [String] {
        get {
            if let value = UserDefaults.standard.value(forKey: UserDefaultsKey.tags) as? [String] {
                return value
            } else {
                UserDefaults.standard.set(["❤️"], forKey: UserDefaultsKey.tags)
                return UserDefaults.standard.value(forKey: UserDefaultsKey.tags) as! [String]
            }
        } set {
            UserDefaults.standard.setValue(newValue, forKey: UserDefaultsKey.tags)
        }
    }
    
    internal static var locationTags: [String] {
        get {
            if let value = UserDefaults.standard.value(forKey: UserDefaultsKey.locationTags) as? [String] {
                return value
            } else {
                UserDefaults.standard.set(["🍽"], forKey: UserDefaultsKey.locationTags)
                return UserDefaults.standard.value(forKey: UserDefaultsKey.locationTags) as! [String]
            }
        } set {
            UserDefaults.standard.setValue(newValue, forKey: UserDefaultsKey.locationTags)
        }
    }
    
    internal static let defaultTags: [DefaultTagType] = [DefaultTagType.clipboard, DefaultTagType.location]
    internal static let lockStr = "🔒"
    internal static let shareStr = "👫"
    internal static let limitPasteStrCount = 500
    internal static let textViewInsetBottom: CGFloat = 100
    internal static var lineSpacing: CGFloat {
        let pointSize = Font.preferredFont(forTextStyle: .body).pointSize
        if pointSize < 16 {
            return 10
        } else if pointSize < 20 {
            return 8
        } else {
            return 6
        }
    }
    
    internal static var numWidth: CGFloat {
        let pointSize = Font.preferredFont(forTextStyle: .body).pointSize
        if pointSize < 16 {
            return 21
        } else if pointSize < 20 {
            return 25
        } else {
            return 29
        }
    }
    
    internal static let formWidth: CGFloat = 30
    internal static let defaultAttr: [NSAttributedString.Key : Any] = [
        .foregroundColor: textColor,
        .font: defaultFont,
        .strikethroughStyle : 0,
        .kern: 0,
        .paragraphStyle : ParagraphStyle()]
    
    internal static let numAttr: [NSAttributedString.Key : Any] = [
        .foregroundColor : effectColor,
        .font : defaultFont,
        .kern: 0]
    
    internal static func punctuationAttr(num: String) -> [NSAttributedString.Key : Any] {
        return [.foregroundColor: punctuationColor,
                .font: defaultFont,
                .kern: kern(num: num)
        ]
    }
    
    internal static func formAttr(form: String) -> [NSAttributedString.Key : Any] {
        return [.foregroundColor: textColor,
                .font: defaultFont,
                .kern: kern(form: form)]
    }
    
    internal static let defaultTypingAttr: [NSAttributedString.Key : Any] = [
        NSAttributedString.Key.foregroundColor : textColor,
        NSAttributedString.Key.font : defaultFont]
    
    internal static let strikeThroughAttr: [NSAttributedString.Key : Any] = [.strikethroughStyle : 1,
                                                                             .foregroundColor : Preference.strikeThroughColor,
                                                                             .strikethroughColor : Preference.strikeThroughColor,
                                                                             .font : Preference.defaultFont]
    

    
    internal static func kern(num: String) -> CGFloat {
        let attrNumWidth = NSAttributedString(string: num + ". ", attributes: [.font: defaultFont]).size().width
        return attrNumWidth > numWidth ? 0 : numWidth - attrNumWidth
    }
    
    
    
    internal static func kern(form: String) -> CGFloat {
        let emoji = NSAttributedString(string: form, attributes: [
            .font : defaultFont]).size()
        return emoji.width > formWidth ? 0 : formWidth - emoji.width
    }
    
    internal static func paragraphStyle(form: String, whitespace: String, kern: CGFloat) -> ParagraphStyle {
        let paragraphStyle = MutableParagraphStyle()
        
        var string = form
        if Int(form) != nil {
            string += "."
        }
        
        let attrString = NSAttributedString(string: whitespace + string + " ",
                                            attributes: [.font: Preference.defaultFont, .kern: 0])
        paragraphStyle.headIndent = attrString.size().width + kern
        return paragraphStyle
    }
    
}

extension Preference {
    static let firstList = ["🐶","🐱","🐭","🐹","🐰","🦊","🐻","🐼","🐨","🐯","🦁","🐮","🐷","🐽","🐸","🐵","🙈","🙉","🙊","🐒","🐔","🐧","🐦","🐤","🐣","🐥","🦆","🦅","🦉","🦇","🐺","🐗","🐴","🦄","🐝","🐛","🦋","🐌","🐚","🐞","🐜","🦗","🕷","🕸","🦂","🐢","🐍","🦎","🦖","🦕","🐙","🦑","🦐","🦀","🐡","🐠","🐟","🐬","🐳","🐋","🦈","🐊","🐅","🐆","🦓","🦍","🐘","🦏","🐪","🐫","🦒","🐃","🐂","🐄","🐎","🐖","🐏","🐑","🐐","🦌","🐕","🐩","🐈","🐓","🦃","🕊","🐇","🐁","🐀","🐿","🦔","🐾","🐉","🐲","🌵","🎄","🌲","🌳","🌴","🌱","🌿","☘️","🍀","🎍","🎋","🍃","🍂","🍁","🍄","🌾","💐","🌷","🌹","🥀","🌺","🌸","🌼","🌻","🌞","🌝","🌛","🌜","🌚","🌕","🌖","🌗","🌘","🌑","🌒","🌓","🌔","🌙","🌎","🌍","🌏","💫","⭐️","🌟","✨","⚡️","☄️","💥","🔥","🌪","🌈","☀️","🌤","⛅️","🌥","☁️","🌦","🌧","⛈","🌩","🌨","❄️","☃️","⛄️","🌬","💨","💧","💦","☔️","☂️","🌊","🌫"]
    
    static let secondList = ["🍏","🍎","🍐","🍊","🍋","🍌","🍉","🍇","🍓","🍈","🍒","🍑","🍍","🥥","🥝","🍅","🍆","🥑","🥦","🥒","🌶","🌽","🥕","🥔","🍠","🥐","🍞","🥖","🥨","🧀","🥚","🍳","🥞","🥓","🥩","🍗","🍖","🌭","🍔","🍟","🍕","🥪","🥙","🌮","🌯","🥗","🥘","🥫","🍝","🍜","🍲","🍛","🍣","🍱","🥟","🍤","🍙","🍚","🍘","🍥","🥠","🍢","🍡","🍧","🍨","🍦","🥧","🍰","🎂","🍮","🍭","🍬","🍫","🍿","🍩","🍪","🌰","🥜","🍯","🥛","🍼","☕️","🍵","🥤","🍶","🍺","🍻","🥂","🍷","🥃","🍸","🍹","🍾","🥄","🍴","🍽","🥣","🥡","🥢"]
    
    static let checkOnList = ["🙆‍♀️", "🙆🏻‍♀️", "🙆🏼‍♀️", "🙆🏽‍♀️", "🙆🏾‍♀️", "🙆🏿‍♀️", "🙆‍♂️", "🙆🏻‍♂️", "🙆🏼‍♂️", "🙆🏽‍♂️", "🙆🏾‍♂️", "🙆🏿‍♂️", "✅", "☠️", "👻", "👌", "👍", "👏"]
    static let checkOffList = ["🙅‍♀️", "🙅🏻‍♀️", "🙅🏼‍♀️", "🙅🏽‍♀️", "🙅🏾‍♀️", "🙅🏿‍♀️", "🙅‍♂️", "🙅🏻‍♂️", "🙅🏼‍♂️", "🙅🏽‍♂️", "🙅🏾‍♂️", "🙅🏿‍♂️", "❎", "💀", "💩", "🤞", "💪", "🙌"]
}
