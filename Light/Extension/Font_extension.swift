//
//  Font_extension.swift
//  Block
//
//  Created by Kevin Kim on 2018. 7. 16..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

//extension Font {
//    func withTraits(traits: FontDescriptorSymbolicTraits) -> Font {
//        let descriptor = fontDescriptor.withSymbolicTraits(traits)
//        return Font(descriptor: descriptor!, size: 0) //size 0 means keep the size as it is
//    }
//
//    func bold() -> Font {
//        return withTraits(traits: .traitBold)
//    }
//
//    func extraBold() -> Font {
//        UIFont.Weight.heavy
//        UIFontDescriptor.preferredFontDescriptor(withTextStyle: UIFont.TextStyle.body, compatibleWith: UITraitCollection
//        var descriptor = UIFontDescriptor(name: "Helvetica Neue", size: 24.0)
//        descriptor = descriptor.addingAttributes([UIFontDescriptor.AttributeName.traits : [UIFontDescriptor.TraitKey.weight : UIFont.Weight.light]])
//        let font = UIFont(descriptor: descriptor, size: 24.0)
//    }
//
//
//    func italic() -> Font {
//        return withTraits(traits: .traitItalic)
//    }
//
//
//}

extension UIFont {
    var black: UIFont { return withWeight(.black) }
    var medium: UIFont { return withWeight(.medium) }
    var thin: UIFont { return withWeight(.thin) }
    var body: UIFont { return withWeight(.regular) }
    
    private func withWeight(_ weight: UIFont.Weight) -> UIFont {
//        var attributes = fontDescriptor.fontAttributes
//        var traits = (attributes[.traits] as? [UIFontDescriptor.TraitKey: Any]) ?? [:]
//
//        traits[.weight] = weight
//
//        attributes[.name] = nil
//        attributes[.traits] = traits
//        attributes[.family] = familyName
//
//        let descriptor = UIFontDescriptor(fontAttributes: attributes)
        return UIFont.systemFont(ofSize: pointSize, weight: weight)
    }
    

}
