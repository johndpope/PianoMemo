//
//  Font_extension.swift
//  Block
//
//  Created by Kevin Kim on 2018. 7. 16..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation

extension Font {
    func withTraits(traits: FontDescriptorSymbolicTraits) -> Font {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return Font(descriptor: descriptor!, size: 0) //size 0 means keep the size as it is
    }
    
    func bold() -> Font {
        return withTraits(traits: .traitBold)
    }
    
    func italic() -> Font {
        return withTraits(traits: .traitItalic)
    }
}
