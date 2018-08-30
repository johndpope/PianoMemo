//
//  String_extension.swift
//  Block
//
//  Created by Kevin Kim on 2018. 7. 25..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreText

extension String {
   
    var loc: String {
        return NSLocalizedString(self, comment: "")
    }
    
    var dataDetector: Any? {
        let types: NSTextCheckingResult.CheckingType = [.date, .phoneNumber, .address, .link]
        let detector = try? NSDataDetector(types:types.rawValue)
        if let match = detector?.firstMatch(in: self, options: .reportCompletion, range: NSMakeRange(0, count)) {
            switch match.resultType {
            case .address: return match.addressComponents
            case .date: return match.date
            case .phoneNumber: return match.phoneNumber
            case .link: return match.url
            default: break
            }
        }
        return nil
    }
    
}

extension String {
    
    var glyphCount: Int {
        
        let richText = NSAttributedString(string: self)
        let line = CTLineCreateWithAttributedString(richText)
        return CTLineGetGlyphCount(line)
    }
    
    var isSingleEmoji: Bool {
        
        return glyphCount == 1 && containsEmoji
    }
    
    var containsEmoji: Bool {
        
        return unicodeScalars.contains { $0.isEmoji }
    }
    
    var containsOnlyEmoji: Bool {
        
        return !isEmpty
            && !unicodeScalars.contains(where: {
                !$0.isEmoji
                    && !$0.isZeroWidthJoiner
            })
    }
    
    // The next tricks are mostly to demonstrate how tricky it can be to determine emoji's
    // If anyone has suggestions how to improve this, please let me know
    var emojiString: String {
        
        return emojiScalars.map { String($0) }.reduce("", +)
    }
    
//    var emojis: [String] {
//
//        var scalars: [[UnicodeScalar]] = []
//        var currentScalarSet: [UnicodeScalar] = []
//        var previousScalar: UnicodeScalar?
//
//        for scalar in emojiScalars {
//
//            if let prev = previousScalar, !prev.isZeroWidthJoiner && !scalar.isZeroWidthJoiner {
//
//                scalars.append(currentScalarSet)
//                currentScalarSet = []
//            }
//            currentScalarSet.append(scalar)
//
//            previousScalar = scalar
//        }
//
//        scalars.append(currentScalarSet)
//
//        return scalars.map { $0.map{ String($0) } .reduce("", +) }
//    }

    var emojis: [String] {
        return self.filter { String($0).containsEmoji }.map { String($0) }
    }
    
    fileprivate var emojiScalars: [UnicodeScalar] {
        
        var chars: [UnicodeScalar] = []
        var previous: UnicodeScalar?
        for cur in unicodeScalars {
            
            if let previous = previous, previous.isZeroWidthJoiner && cur.isEmoji {
                chars.append(previous)
                chars.append(cur)
                
            } else if cur.isEmoji {
                chars.append(cur)
            }
            
            previous = cur
        }
        
        return chars
    }
}

extension String {
    func detect(searchRange: NSRange, regex: String) -> (String, NSRange)? {
        do {
            let regularExpression = try NSRegularExpression(pattern: regex, options: .anchorsMatchLines)
            guard let result = regularExpression.matches(in: self, options: .withTransparentBounds, range: searchRange).first else { return nil }
            let range = result.range(at: 1)
            let string = (self as NSString).substring(with: range)
            return (string, range)
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
}

extension String {
    var tokenzied: [String] {
        if let language = NSLinguisticTagger.dominantLanguage(for: self),
            NSLinguisticTagger.availableTagSchemes(forLanguage: language).contains(.lexicalClass) {
            return linguisticTokenize(text: self)
        } else {
            return nonLinguisticTokenize(text: self)
        }
    }

    func predicate(fieldName: String) -> NSPredicate {
        return predicate(tokens: tokenzied, searchField: fieldName)
    }

    private func linguisticTokenize(text: String) -> [String] {
        let tagger = NSLinguisticTagger(tagSchemes: [.lexicalClass], options: 0)
        tagger.string = text.lowercased()

        let range = NSRange(location: 0, length: text.utf16.count)
        let options: NSLinguisticTagger.Options = [.omitWhitespace]
        let tags: [NSLinguisticTag] = [.noun, .verb, .otherWord, .number]
        var words = Array<String>()

        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange, stop in
            if let tag = tag, tags.contains(tag) {
                let word = (text as NSString).substring(with: tokenRange)
                words.append(word)
            }
        }
        return words
    }

    private func nonLinguisticTokenize(text: String) -> [String] {
        let trimmed = text.components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .map { $0.lowercased()
                .trimmingCharacters(in: .illegalCharacters)
                .trimmingCharacters(in: .punctuationCharacters)
            }
            .filter { $0.count > 0 }

        return trimmed
    }

    private func predicate(tokens: [String], searchField: String) -> NSPredicate {
        let predicates = Set(tokens).map { NSPredicate(format: "\(searchField) contains[cd] %@", $0) }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}


extension String {
    func substring(with range: NSRange) -> String {
        let substring = self[self.index(self.startIndex, offsetBy: range.lowerBound) ..< self.index(self.startIndex, offsetBy: range.upperBound)]
        return String(substring)
    }
}



extension String {
    internal func createFormatAttrString() -> NSAttributedString {
        
        let nsString = self as NSString
        var range = NSMakeRange(0, 0)
        let mutableAttrString = NSMutableAttributedString(string: self, attributes: Preference.defaultAttr)
        while range.location < mutableAttrString.length {
            let paraRange = nsString.paragraphRange(for: range)
            guard let bulletValue = BulletValue(nsText: nsString, selectedRange: range) else { break }
            mutableAttrString.transform(bulletValue: bulletValue)
            range.location = paraRange.location + paraRange.length
        }
        
        return mutableAttrString
    }

}
