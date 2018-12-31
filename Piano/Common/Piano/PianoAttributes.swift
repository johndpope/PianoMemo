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
    case backgroundColor = 0

    func add(from attr: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {

        var newAttr = attr
        switch self {
        case .backgroundColor:
            newAttr[.backgroundColor] = Color.highlight
        }
        return newAttr
    }

    func erase(from attr: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        var newAttr = attr
        switch self {
        case .backgroundColor:
            newAttr[.backgroundColor] = Color.clear
        }
        return newAttr
    }
}
