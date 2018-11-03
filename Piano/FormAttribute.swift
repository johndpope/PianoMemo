//
//  FormAttribute.swift
//  Piano
//
//  Created by Kevin Kim on 23/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CoreGraphics

struct FormAttribute {
    
    internal static let defaultAttrForPDF: [NSAttributedString.Key : Any] = [
        .foregroundColor: textColor,
        .font: defaultFont.withSize(12),
        .strikethroughStyle : 0]
    
    
    internal static let defaultFont = Font.preferredFont(forTextStyle: .body)
    internal static let textColor: Color = Color.darkText
    internal static let effectColor: Color = Color.point
    internal static let punctuationColor: Color = Color.lightGray
    internal static let strikeThroughColor: Color = Color.lightGray
    
    internal static let defaultAttr: [NSAttributedString.Key : Any] = [
        .foregroundColor: textColor,
        .font: defaultFont,
        .strikethroughStyle : 0]
    
    internal static let strikeThroughAttr: [NSAttributedString.Key : Any] = [.strikethroughStyle : 1,
                                                                             .foregroundColor : FormAttribute.strikeThroughColor,
                                                                             .strikethroughColor : FormAttribute.strikeThroughColor,
                                                                             .font : FormAttribute.defaultFont]
    
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
    
    internal static let numAttr: [NSAttributedString.Key : Any] = [
        .foregroundColor : effectColor,
        .font : defaultFont]
    
    internal static let punctuationAttr: [NSAttributedString.Key : Any] = [
        .font : defaultFont]
    
    internal static let formAttr: [NSAttributedString.Key : Any] = [
        .font : defaultFont]
    
    internal static let sharpFont = Font.preferredFont(forTextStyle: .caption2).withSize(8)
    
}