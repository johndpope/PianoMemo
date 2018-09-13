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
//public typealias Responder = UIResponder
//public typealias Image = UIImage
//public typealias Color = UIColor
//public typealias Font = UIFont

#elseif os(macOS)
import AppKit
public typealias Responder = NSResponder
public typealias Image = NSImage
public typealias Color = NSColor
public typealias Font = NSFont
public typealias MutableParagraphStyle = NSMutableParagraphStyle
public typealias ParagraphStyle = NSParagraphStyle

#endif

struct Preference {
    #if os(iOS)
    internal static let textColor: Color = Color.darkText
    internal static let defaultFont = Font.preferredFont(forTextStyle: .body)
    internal static let numFont = Font(name: "Avenir Next", size: Font.preferredFont(forTextStyle: .body).pointSize)!
    #elseif os(macOS)
    internal static let textColor: Color = Color.textColor
    internal static let defaultFont = Font.systemFont(ofSize: 14, weight: .medium)
    internal static let numFont = Font(name: "Avenir Next", size: defaultFont.pointSize)!
    #endif

    internal static let effectColor: Color = Color.red
    internal static let punctuationColor: Color = Color.lightGray
    internal static let strikeThroughColor: Color = Color.lightGray
    internal static let formFont = Font.systemFont(ofSize: 23)
    
    
    internal static let checkOnValue = "🙆‍♀️"
    internal static let checkOffValue = "🙅‍♀️"
    internal static let idealistValue = "💡"
    internal static let idealistKey = "?"
    internal static let unOrderedlistValue = "😁"
    internal static let checklistKey = "-"
    internal static let unorderedlistKey = "*"
    internal static let lineSpacing: CGFloat = 6
    internal static let punctuationKern: CGFloat = 15
    internal static let defaultAttr: [NSAttributedStringKey : Any] = [
        .foregroundColor: textColor,
        .font: defaultFont,
        .strikethroughStyle : 0,
        .paragraphStyle : ParagraphStyle()]
    
    internal static let numAttr: [NSAttributedStringKey : Any] = [
        .foregroundColor : effectColor,
        .font : numFont]
    
    internal static let punctuationAttr: [NSAttributedStringKey : Any] = [
        .foregroundColor : punctuationColor,
        .font : defaultFont,
        .kern : punctuationKern]
    
    internal static func formAttr(form: String) -> [NSAttributedStringKey : Any] {
        return [.foregroundColor: textColor,
                .font: formFont,
                .kern: kern(form: form)]
    }
    
    internal static let defaultTypingAttr: [String : Any] = [
        NSAttributedStringKey.foregroundColor.rawValue : textColor,
        NSAttributedStringKey.font.rawValue : defaultFont]
    
    
    
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

