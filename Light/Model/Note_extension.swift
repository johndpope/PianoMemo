//
//  Note_extension.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreGraphics

struct LightAttribute: Codable {
    let highlights: [NSRange]
}

extension Note {
    var atttributes: LightAttribute? {
        get {
            guard let attributeData = attributeData else { return nil }
            return try? JSONDecoder().decode(LightAttribute.self, from: attributeData)
        } set {
            let data = try? JSONEncoder().encode(newValue)
            attributeData = data
        }
    }
}
