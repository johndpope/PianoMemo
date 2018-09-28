//
//  PianoAttributes.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 4..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreGraphics

enum PianoAttributes: Int {
    case foregroundColor = 0
    
    
    func add(from attr: [NSAttributedString.Key : Any]) -> [NSAttributedString.Key : Any] {
        
        var newAttr = attr
        switch self {
        case .foregroundColor:
            newAttr[.foregroundColor] = Color.highlight
        }
        return newAttr
    }
    
    func erase(from attr: [NSAttributedString.Key : Any]) -> [NSAttributedString.Key : Any] {
        var newAttr = attr
        switch self {
        case .foregroundColor:
            newAttr[.foregroundColor] = Preference.textColor
        }
        return newAttr
    }
}

