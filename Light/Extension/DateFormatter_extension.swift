//
//  DateFormatter.swift
//  Block
//
//  Created by Kevin Kim on 2018. 7. 12..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation

extension DateFormatter {
    
    static let sharedInstance: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
    
    static let longSharedInstance: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = false
        return formatter
    }()
    
    /**
     해당 style을 가지는 Formatter를 반환한다.
     - parameter style : [dateStyle, timeStyle]
     */
    static func style(_ style: [DateFormatter.Style]) -> DateFormatter {
        let format = DateFormatter()
        format.dateStyle = style[0]
        switch style.count {
        case 0...1: format.timeStyle = .none
        case 2: format.timeStyle = style[1]
        default: break
        }
        return format
    }
    
    /**
     해당 format을 가지는 Formatter를 반환한다.
     - parameter format : dateFormat.
     */
    static func format(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter
    }
    
}
