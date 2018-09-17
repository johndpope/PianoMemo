//
//  Preference.swift
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
    internal static let defaultFontSize = Font.preferredFont(forTextStyle: .body).pointSize
    internal static let defaultFont = Font.preferredFont(forTextStyle: .body).withSize(23)
    #elseif os(OSX)

    internal static let textColor: Color = NSColor.darkGray
    internal static let defaultFont = NSFont.systemFont(ofSize: 40, weight: .light)

    #endif
    internal static let numFont = Font(name: "Avenir Next", size: defaultFont.pointSize)!

    internal static let effectColor: Color = Color.point
    internal static let punctuationColor: Color = Color.lightGray
    internal static let strikeThroughColor: Color = Color.lightGray
    internal static let formFont = defaultFont
    
    
    internal static let checkOnValue = "🙆‍♀️"
    internal static let checkOffValue = "🙅‍♀️"
    internal static let idealistValue = "💡"
    internal static let idealistKey = "?"
    internal static let unOrderedlistValue = "🔹"
    internal static let checklistKey = "-"
    internal static let unorderedlistKey = "*"
    internal static let lineSpacing: CGFloat = 6
    internal static let punctuationKern: CGFloat = 15
    internal static let defaultAttr: [NSAttributedString.Key : Any] = [
        .foregroundColor: textColor,
        .font: defaultFont,
        .strikethroughStyle : 0,
        .paragraphStyle : ParagraphStyle()]
    
    internal static let numAttr: [NSAttributedString.Key : Any] = [
        .foregroundColor : effectColor,
        .font : numFont]
    
    internal static let punctuationAttr: [NSAttributedString.Key : Any] = [
        .foregroundColor : punctuationColor,
        .font : defaultFont,
        .kern : punctuationKern]
    
    internal static func formAttr(form: String) -> [NSAttributedString.Key : Any] {
        return [.foregroundColor: textColor,
                .font: formFont,
                .kern: kern(form: form)]
    }
    
    internal static let defaultTypingAttr: [NSAttributedString.Key : Any] = [
        NSAttributedString.Key.foregroundColor : textColor,
        NSAttributedString.Key.font : defaultFont]
    
    
    
    internal static func kern(form: String) -> CGFloat {
        let num = NSAttributedString(string: "4", attributes: [
            .font : numFont]).size()
        let dot = NSAttributedString(string: ".", attributes: [
            .font : defaultFont]).size()
        let emoji = NSAttributedString(string: form, attributes: [
            .font : formFont]).size()
        
        return (num.width + dot.width + punctuationKern - emoji.width)
    }
}

