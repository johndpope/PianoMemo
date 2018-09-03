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

protocol Rangeable {
    var range: NSRange { get set }
}

//MARK: link Data
extension String {
    struct Reminder {
        let title: String
        let calendar: Calendar?
        let isCompleted: Bool
    }
    
    internal func reminder() -> Reminder? {
        do {
            let regex = try NSRegularExpression(pattern: "^\\s*(\\S+)(?= )", options: .anchorsMatchLines)
            let searchRange = NSMakeRange(0, count)
            
            guard let result = regex.matches(in: self, options: .withTransparentBounds, range: searchRange).first else { return nil }
            let range = result.range(at: 1)
            let nsString = self as NSString
            let string = nsString.substring(with: range)
            if string == "🙅‍♀️" || string == "🙆‍♀️" {
                let contentString = nsString.substring(from: range.upperBound + 1)
                
                let calendar = contentString.calendar()
                
                let data = Reminder(title: calendar?.title ?? contentString, calendar: calendar, isCompleted: string != "🙅‍♀️")
                return data
            }
            
        } catch {
            print("string_extension reminder() 에러: \(error.localizedDescription)")
        }
        return nil
    }
    
    struct Contact {
        let givenName: String
        let familyName: String
        let phones: [String]
        let addresses: [(NSTextCheckingKey, String)]
        let mails: [String]
    }
    
    struct Phone: Rangeable {
        let string: String
        var range: NSRange
    }
    
    struct Address: Rangeable {
        let string: String
        let checkingKey: NSTextCheckingKey
        var range: NSRange
    }
    
    struct Mail: Rangeable {
        let string: String
        var range: NSRange
    }
    
    internal func contact() -> Contact? {
        let types: NSTextCheckingResult.CheckingType = [.phoneNumber, .address, .link]
        do {
            let detector = try NSDataDetector(types: types.rawValue)
            let searchRange = NSMakeRange(0, count)
            
            
            var contacts: [Rangeable] = []
            let matches = detector.matches(in: self, options: .reportCompletion, range: searchRange)
            
            for match in matches {
                if let phoneNumber = match.phoneNumber {
                    let phone = Phone(string: phoneNumber, range: match.range)
                    contacts.append(phone)
                    
                } else if let urlStr = match.url?.absoluteString,
                    let mailStr = urlStr.components(separatedBy: ":").last,
                    urlStr.contains("mailto")  {
                    let mail = Mail(string: mailStr, range: match.range)
                    contacts.append(mail)
                } else if let addressKey = match.addressComponents?.keys.first,
                    let addressStr = match.addressComponents?.values.first {
                    let address = Address(string: addressStr, checkingKey: addressKey, range: match.range)
                    contacts.append(address)
                }
            }
            
            contacts.sort{ $0.range.location > $1.range.location }
            
            var text = self
            var phones: [String] = []
            var addresses: [(NSTextCheckingKey, String)] = []
            var mails: [String] = []
            contacts.forEach { (contact) in
                if let phone = contact as? Phone {
                    if let phoneRange = Range(phone.range, in: text) {
                        text.removeSubrange(phoneRange)
                    }
                    phones.append(phone.string)
                } else if let address = contact as? Address {
                    if let addressRange = Range(address.range, in: text) {
                        text.removeSubrange(addressRange)
                    }
                    addresses.append((address.checkingKey, address.string))

                    
                } else if let mail = contact as? Mail {
                    if let mailRange = Range(mail.range, in: text) {
                        text.removeSubrange(mailRange)
                    }
                    mails.append(mail.string)
                }
            }
            
            if text.trimmingCharacters(in: .whitespaces).count != 0 {
                let allName = text.components(separatedBy: .whitespaces)
                let names = allName.filter { $0.count != 0 }
                return Contact(givenName: names.first!, familyName: names.count > 1 ? names.last! : "", phones: phones, addresses: addresses, mails: mails)
            }
            
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    struct Calendar {
        let title: String
        let startDate: Date
        let endDate: Date
    }
    
    internal func calendar() -> Calendar? {
        let types: NSTextCheckingResult.CheckingType = [.date]
        do {
            let detector = try NSDataDetector(types:types.rawValue)
            let searchRange = NSMakeRange(0, count)
            
            var events: [(date: Date, range: NSRange)] = []
            let matches = detector.matches(in: self, options: .reportCompletion, range: searchRange)
            
            for match in matches {
                if let date = match.date {
                    //duration이 0이 아니라면 startDate, endDate를 잡고 그 range 제외하고 제목으로 만들어서 캘린더 리턴하기
                    if match.duration != 0 {
                        var title = self
                        if let dateRange = Range(match.range,  in: title) {
                            title.removeSubrange(dateRange)
                        }
                        
                        if title.trimmingCharacters(in: .whitespacesAndNewlines).count != 0 {
                            let startDate = date
                            let endDate = date.addingTimeInterval(match.duration)
                            return Calendar(title: title, startDate: startDate, endDate: endDate)
                        }
                        
                    }
                    
                    
                    events.append((date, match.range))
                }
            }
            
            guard let startEvent = events.first,
                let endEvent = events.last else { return nil }
            
            if startEvent.range.location < endEvent.range.location {
                //두개의 date가 다르다면 두 range를 뺀 나머지를 제목으로 하자
                //뒤에 range를 먼저 리무브하고 앞에 range를 리무브해야함
                var text = self
                if let endEventRange = Range(endEvent.range, in: text) {
                    text.removeSubrange(endEventRange)
                }
                
                if let startEventRange = Range(startEvent.range, in: text) {
                    text.removeSubrange(startEventRange)
                }
                
                if text.trimmingCharacters(in: .whitespacesAndNewlines).count != 0 {
                    return Calendar(title: text, startDate: startEvent.date, endDate: endEvent.date)
                }
                
            } else if startEvent.range.location > endEvent.range.location {
                var text = self
                if let startEventRange = Range(startEvent.range, in: text) {
                    text.removeSubrange(startEventRange)
                }
                
                if let endEventRange = Range(endEvent.range, in: text) {
                    text.removeSubrange(endEventRange)
                }
                
                if text.trimmingCharacters(in: .whitespacesAndNewlines).count != 0 {
                    return Calendar(title: text, startDate: startEvent.date, endDate: endEvent.date)
                }
            }
            else {
                //두개의 date가 같다면 날짜를 startDate만 입력했다는 말 -> 나머지 range를 제목으로하고 endDate를 한시간 뒤로 하자
                var text = self
                if let startEventRange = Range(startEvent.range, in: text) {
                    text.removeSubrange(startEventRange)
                }
                
                if text.count != 0 {
                    return Calendar(title: text, startDate: startEvent.date, endDate: startEvent.date.addingTimeInterval(60 * 60))
                }
            }
            
        } catch {
            print("string_extension calendar() 에러: \(error.localizedDescription)")
        }
        
        return nil
    }
}
