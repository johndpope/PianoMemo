//
//  NSAttributedString_extension.swift
//  Piano
//
//  Created by Kevin Kim on 19/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

extension NSAttributedString.Key {
    public static let animatingBackground = NSAttributedString.Key(rawValue: "animatingBackground")
}

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

extension NSAttributedString {
    //변환해주는 건 아래꺼를 쓰면 된다.
    internal var formatted: NSMutableAttributedString {
        let mutable = NSMutableAttributedString(attributedString: self)
        var range = NSMakeRange(0, 0)
        while true {
            guard range.location < mutable.length else { break }

            let paraRange = (mutable.string as NSString).paragraphRange(for: range)
            range.location = paraRange.location + paraRange.length + 1

            if let bulletKey = BulletKey(text: mutable.string, selectedRange: paraRange) {
                range.location += mutable.transform(bulletKey: bulletKey)
                continue
            }

            if let bulletValue = BulletValue(text: mutable.string, selectedRange: paraRange) {
                mutable.transform(bulletValue: bulletValue)
                continue
            }
        }
        return mutable
    }

    var deformatted: String {
        var range = NSMakeRange(0, 0)
        let mutableAttrString = NSMutableAttributedString(attributedString: self)

        //1.
        while true {
            guard range.location < mutableAttrString.length else { break }
            let paraRange = (mutableAttrString.string as NSString).paragraphRange(for: range)
            range.location = paraRange.location + paraRange.length + 1

            guard let bulletValue = BulletValue(text: mutableAttrString.string, selectedRange: paraRange)
                else { continue }

            mutableAttrString.replaceCharacters(in: bulletValue.range, with: bulletValue.key)
        }

        return mutableAttrString.string
    }
}
