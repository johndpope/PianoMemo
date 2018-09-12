//
//  Preference.swift
//  Emo
//
//  Created by Kevin Kim on 2018. 8. 22..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreGraphics

struct Preference {
    internal static let effectColor: Color = Color.red
    internal static let textColor: Color = Color.darkText
    internal static let punctuationColor: Color = Color.lightGray
    internal static let strikeThroughColor: Color = Color.lightGray
    internal static let defaultFont = Font.systemFont(ofSize: 23)
    internal static let numFont = Font(name: "Avenir Next", size: 23)!
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

