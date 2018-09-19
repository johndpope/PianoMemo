//
//  NSAttributedString_extension.swift
//  Piano
//
//  Created by Kevin Kim on 19/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

extension NSAttributedString {
    

    
//    func saveTo(note: Note) {
//        guard let context = note.managedObjectContext else { return }
//        context.performAndWait {
//            let mutableAttrString = NSMutableAttributedString(attributedString: self)
//
//            while true {
//                if let range = mutableAttrString.string.range(of: Preference.idealistValue) {
//                    let nsRange = NSRange(range, in: mutableAttrString.string)
//                    mutableAttrString.replaceCharacters(in: nsRange, with: Preference.idealistKey)
//                } else {
//                    break
//                }
//            }
//
//            while true {
//                if let range = mutableAttrString.string.range(of: Preference.checklistOffValue) {
//                    let nsRange = NSRange(range, in: mutableAttrString.string)
//                    mutableAttrString.replaceCharacters(in: nsRange, with: Preference.checklistOffKey)
//                } else {
//                    break
//                }
//            }
//
//            while true {
//                if let range = mutableAttrString.string.range(of: Preference.checklistOnValue) {
//                    let nsRange = NSRange(range, in: mutableAttrString.string)
//                    mutableAttrString.replaceCharacters(in: nsRange, with: Preference.checklistOnKey)
//                } else {
//                    break
//                }
//            }
//
//            while true {
//                if let range = mutableAttrString.string.range(of: Preference.firstlistValue) {
//                    let nsRange = NSRange(range, in: mutableAttrString.string)
//                    mutableAttrString.replaceCharacters(in: nsRange, with: Preference.firstlistKey)
//                } else {
//                    break
//                }
//            }
//
//            while true {
//                if let range = mutableAttrString.string.range(of: Preference.secondlistValue) {
//                    let nsRange = NSRange(range, in: mutableAttrString.string)
//                    mutableAttrString.replaceCharacters(in: nsRange, with: Preference.secondlistKey)
//                } else {
//                    break
//                }
//            }
//
//            var ranges: [NSRange] = []
//            mutableAttrString.enumerateAttribute(.backgroundColor, in: NSMakeRange(0, mutableAttrString.length), options: .longestEffectiveRangeNotRequired) { (value, range, _) in
//                guard let backgroundColor = value as? Color, backgroundColor == Color.highlight else { return }
//                ranges.append(range)
//            }
//
//            note.atttributes = NoteAttributes(highlightRanges: ranges)
//            note.content = mutableAttrString.string
//            note.modifiedDate = Date()
//
//            context.saveIfNeeded()
//        }
//
//    }

}
