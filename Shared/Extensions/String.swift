//
//  String.swift
//  Piano
//
//  Created by hoemoon on 26/02/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension String {
    var tokenized: [String] {
        if let language = NSLinguisticTagger.dominantLanguage(for: self),
            NSLinguisticTagger.availableTagSchemes(forLanguage: language).contains(.lexicalClass),
            self.count > 3 {
            return linguisticTokenize(text: self)
        } else {
            return nonLinguisticTokenize(text: self)
        }
    }

    //    func predicate(fieldName: String) -> NSPredicate? {
    //        let resultPredicate = predicate(tokens: tokenzied, searchField: fieldName)
    //        return resultPredicate
    //    }

    private func linguisticTokenize(text: String) -> [String] {
        let tagger = NSLinguisticTagger(tagSchemes: [.lexicalClass], options: 0)
        tagger.string = text.lowercased()

        let range = NSRange(location: 0, length: text.utf16.count)
        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        let tags: [NSLinguisticTag] = [.noun, .verb, .otherWord, .number, .adjective]
        var words = Set<String>()

        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange, _ in
            if let tag = tag, tags.contains(tag) {
                let word = (text as NSString).substring(with: tokenRange)
                words.insert(word)
            }
        }
        // `apple u` 같이 입력될 때 발생하는 오류를 우회하는 코드
        let components = text.components(separatedBy: CharacterSet.whitespaces)
        if components.count > 1 {
            words.insert(components.first!)
        }
        return Array(words)
    }

    private func nonLinguisticTokenize(text: String) -> [String] {
        let set = CharacterSet().union(.whitespacesAndNewlines)
            .union(CharacterSet.punctuationCharacters)

        let trimmed = text.components(separatedBy: set)
            .map { $0.lowercased()
                .trimmingCharacters(in: .illegalCharacters)
                .trimmingCharacters(in: .punctuationCharacters)
            }
            .filter { $0.count > 0 }

        return trimmed
    }
}
