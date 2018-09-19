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

struct LocalPreference {
    #if os(iOS)
    internal static let textColor: Color = Color.darkText
    internal static let defaultFont = Font.preferredFont(forTextStyle: .body)
    #elseif os(OSX)

    internal static let textColor: Color = NSColor.darkGray
    internal static let defaultFont = NSFont.systemFont(ofSize: 40, weight: .light)

    #endif

    internal static let effectColor: Color = Color.point
    internal static let punctuationColor: Color = Color.lightGray
    internal static let strikeThroughColor: Color = Color.lightGray
    
    internal static var checkOnValue = "🙆‍♀️"
    internal static var checkOffValue = "🙅‍♀️"
    internal static let idealistValue = "💡"
    internal static let idealistKey = "?"
    internal static var unOrderedlistValue = "🐶"
    internal static let checklistKey = "@"
    internal static let unorderedlistKey = "-"
    internal static let lineSpacing: CGFloat = 8
    internal static let formWidth: CGFloat = 45
    internal static let defaultAttr: [NSAttributedString.Key : Any] = [
        .foregroundColor: textColor,
        .font: defaultFont,
        .strikethroughStyle : 0,
        .paragraphStyle : ParagraphStyle()]
    
    internal static let numAttr: [NSAttributedString.Key : Any] = [
        .foregroundColor : effectColor,
        .font : defaultFont, .kern: 0]
    
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
                                                                             .foregroundColor : LocalPreference.strikeThroughColor,
                                                                             .strikethroughColor : LocalPreference.strikeThroughColor]
    

    
    internal static func kern(num: String) -> CGFloat {
        let attrNumWidth = NSAttributedString(string: num + ". ", attributes: [.font: defaultFont]).size().width
        return attrNumWidth > formWidth ? 0 : formWidth - attrNumWidth
    }
    
    
    
    internal static func kern(form: String) -> CGFloat {
        let emoji = NSAttributedString(string: form, attributes: [
            .font : defaultFont]).size()
        
        return emoji.width > formWidth ? 0 : formWidth - emoji.width
    }
}

