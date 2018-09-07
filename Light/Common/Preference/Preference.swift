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
    internal static let defaultFont = Font.preferredFont(forTextStyle: .body)
    internal static let numFont = Font(name: "Avenir Next", size: Font.preferredFont(forTextStyle: .body).pointSize)!
    
    
    internal static let checkOnValue = "🙆‍♀️"
    internal static let checkOffValue = "🙅‍♀️"
    internal static let unOrderedlistValue = "⭐️"
    internal static let idealistValue = "💡"
    internal static let idealistKey = "?"
    internal static let checklistKey = "-"
    internal static let unorderedlistKey = "*"
    internal static let lineSpacing: CGFloat = 10
    internal static let punctuationKern: CGFloat = 10
    internal static let defaultAttr: [NSAttributedStringKey : Any] = [
        .foregroundColor: textColor,
        .font: defaultFont]
    
    internal static let numAttr: [NSAttributedStringKey : Any] = [
        .foregroundColor : effectColor,
        .font : numFont]
    
    internal static let punctuationAttr: [NSAttributedStringKey : Any] = [
        .foregroundColor : punctuationColor,
        .font : defaultFont,
        .kern : punctuationKern]
    
    internal static func emojiAttr(emoji: String) -> [NSAttributedStringKey : Any] {
        return [.foregroundColor: textColor,
                .font: defaultFont,
                .kern: kern(form: emoji)]
    }
    
    internal static let defaultTypingAttr: [String : Any] = [
        NSAttributedStringKey.foregroundColor.rawValue : textColor,
        NSAttributedStringKey.backgroundColor.rawValue : Color.clear,
        NSAttributedStringKey.font.rawValue : defaultFont,
        NSAttributedStringKey.kern.rawValue : 0]
    

    
    internal static func kern(form: String) -> CGFloat {
        let num = NSAttributedString(string: "4", attributes: [
            .font : numFont]).size()
        let dot = NSAttributedString(string: ".", attributes: [
            .font : defaultFont]).size()
        let form = NSAttributedString(string: form, attributes: [
            .font : defaultFont]).size()
        
        return (num.width + dot.width + punctuationKern - form.width)
    }

}
