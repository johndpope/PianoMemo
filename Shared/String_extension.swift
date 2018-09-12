//
//  String_extension.swift
//  Block
//
//  Created by Kevin Kim on 2018. 7. 25..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreText
import EventKit
import Contacts

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
    
    /**
     한글을 초,중,종성으로 분리하여준다.
     */
    var hangul: String {
        get {
            let hangle = [
                ["ㄱ","ㄲ","ㄴ","ㄷ","ㄸ","ㄹ","ㅁ","ㅂ","ㅃ","ㅅ","ㅆ","ㅇ","ㅈ","ㅉ","ㅊ","ㅋ","ㅌ","ㅍ","ㅎ"],
                ["ㅏ","ㅐ","ㅑ","ㅒ","ㅓ","ㅔ","ㅕ","ㅖ","ㅗ","ㅘ","ㅙ","ㅚ","ㅛ","ㅜ","ㅝ","ㅞ","ㅟ","ㅠ","ㅡ","ㅢ","ㅣ"],
                ["","ㄱ","ㄲ","ㄳ","ㄴ","ㄵ","ㄶ","ㄷ","ㄹ","ㄺ","ㄻ","ㄼ","ㄽ","ㄾ","ㄿ","ㅀ","ㅁ","ㅂ","ㅄ","ㅅ","ㅆ","ㅇ","ㅈ","ㅊ","ㅋ","ㅌ","ㅍ","ㅎ"]
            ]
            
            return reduce("") { result, char in
                
                if case let code = Int(String(char).unicodeScalars.reduce(0, { (value, scalar) -> UInt32 in
                    return value + scalar.value
                })) - 44032, code > -1 && code < 11172 {
                    let cho = code / 21 / 28, jung = code % (21 * 28) / 28, jong = code % 28;
                    return result + hangle[0][cho] + hangle[1][jung] + hangle[2][jong]
                }
                
                return result + String(char)
            }
        }
    }
    
    /**
     앞에서부터 찾고자 하는 string의 index를 반환한다.
     - parameter of : 찾고자 하는 string.
     - returns : 찾고자 하는 string의 index값.
     */
    func index(of: String) -> Int {
        if let range = range(of: of) {
            return distance(from: startIndex, to: range.lowerBound)
        } else {
            return 0
        }
    }
    
    /**
     앞에서부터 특정 위치까지 찾고자 하는 string의 index를 반환한다.
     - parameter of : 찾고자 하는 string.
     - parameter from : Start index값.
     - returns : 찾고자 하는 string의 index값.
     */
    func index(of: String, from: Int) -> Int {
        let fromIndex = index(startIndex, offsetBy: from)
        let startRange = Range(uncheckedBounds: (lower: fromIndex, upper: endIndex))
        if let range = range(of: of, range: startRange, locale: nil) {
            return distance(from: startIndex, to: range.lowerBound)
        } else {
            return 0
        }
    }
    
    /**
     뒤에서부터 찾고자 하는 string의 index를 반환한다.
     - parameter lastOf : 찾고자 하는 string.
     - returns : 찾고자 하는 string의 index값.
     */
    func index(lastOf: String) -> Int {
        if let range = range(of: lastOf, options: .backwards, range: nil, locale: nil) {
            return distance(from: startIndex, to: range.upperBound)
        } else {
            return 0
        }
    }
    
    /**
     뒤에서부터 특정 위치까지 찾고자 하는 string의 index를 반환한다.
     - parameter lastOf : 찾고자 하는 string.
     - parameter to : End index값.
     - returns : 찾고자 하는 string의 index값.
     */
    func index(lastOf: String, to: Int) -> Int {
        let toIndex = index(startIndex, offsetBy: to)
        let startRange = Range(uncheckedBounds: (lower: toIndex, upper: endIndex))
        if let range = range(of: lastOf, range: startRange, locale: nil) {
            return distance(from: startIndex, to: range.upperBound)
        } else {
            return 0
        }
    }
    
    /**
     Subtring값을 반환한다.
     - parameter r : [value ..< value]
     - returns : 해당 range만큼의 string값.
     */
    func sub(_ r: CountableRange<Int>) -> String {
        let from = (r.startIndex > 0) ? index(startIndex, offsetBy: r.startIndex) : startIndex
        let to = (count > r.endIndex) ? index(startIndex, offsetBy: r.endIndex) : endIndex
        if from >= startIndex && to <= endIndex {
            return String(self[from..<to])
        }
        return self
    }
    
    /**
     Subtring값을 반환한다.
     - parameter r : [value ... value]
     - returns : 해당 range만큼의 string값.
     */
    func sub(_ r: CountableClosedRange<Int>) -> String {
        return sub(r.lowerBound..<r.upperBound)
    }
    
    /**
     Subtring값을 반환한다.
     - parameter r : [value ...]
     - returns : 해당 range만큼의 string값.
     */
    func sub(_ r: CountablePartialRangeFrom<Int>) -> String {
        return sub(r.lowerBound..<count)
    }
    
    /**
     Subtring값을 반환한다.
     - parameter r : [... value]
     - returns : 해당 range만큼의 string값.
     */
    func sub(_ r: PartialRangeThrough<Int>) -> String {
        return sub(0..<r.upperBound)
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

    func predicate(fieldName: String) -> NSPredicate? {
        let resultPredicate = predicate(tokens: tokenzied, searchField: fieldName)
        return resultPredicate
    }

    private func linguisticTokenize(text: String) -> [String] {
        let tagger = NSLinguisticTagger(tagSchemes: [.lexicalClass], options: 0)
        tagger.string = text.lowercased()

        let range = NSRange(location: 0, length: text.utf16.count)
        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        let tags: [NSLinguisticTag] = [.noun, .verb, .otherWord, .number, .adjective]
        var words = Set<String>()

        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange, stop in
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
    internal func createFormatAttrString() -> NSMutableAttributedString {
        

        var range = NSMakeRange(0, 0)
        let mutableAttrString = NSMutableAttributedString(string: self, attributes: Preference.defaultAttr)
        while range.location < mutableAttrString.length {
            
            let paraRange = (self as NSString).paragraphRange(for: range)
            range.location = paraRange.location + paraRange.length + 1
            guard let bulletValue = BulletValue(text: self, selectedRange: paraRange) else {
                continue
            }
            mutableAttrString.transform(bulletValue: bulletValue)
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
        let event: Event?
        let isCompleted: Bool
        
        func createEKReminder(store: EKEventStore) -> EKReminder {
            let ekReminder = EKReminder(eventStore: store)
            ekReminder.title = self.title
            if let event = self.event {
                ekReminder.title = event.title
                let alarm = EKAlarm(absoluteDate: event.startDate)
                ekReminder.addAlarm(alarm)
            }
        
            ekReminder.calendar = store.defaultCalendarForNewReminders()
            ekReminder.isCompleted = self.isCompleted
            return ekReminder
        }
    }
    
    internal func reminder() -> Reminder? {
        do {
            let regex = try NSRegularExpression(pattern: "^\\s*(\\S+)(?= )", options: .anchorsMatchLines)
            let searchRange = NSMakeRange(0, count)
            
            guard let result = regex.matches(in: self, options: .withTransparentBounds, range: searchRange).first else { return nil }
            let range = result.range(at: 1)
            let nsString = self as NSString
            let string = nsString.substring(with: range)
            if string == Preference.checkOffValue || string == Preference.checkOnValue {
                let contentString = nsString.substring(from: range.upperBound + 1)
                
                let event = contentString.event()
                
                let data = Reminder(title: event?.title ?? contentString, event: event, isCompleted: string != Preference.checkOffValue)
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
        let mails: [String]
        
        
        func createCNContact() -> CNContact {
            //연락처 만들어줘서 identifier를 get해야함
            let cnContact = CNMutableContact()
            cnContact.givenName = self.givenName
            cnContact.familyName = self.familyName
            
            phones.forEach { (phone) in
                let phoneNumber = CNLabeledValue(label: CNLabelPhoneNumberiPhone,
                                                 value: CNPhoneNumber(stringValue: phone))
                cnContact.phoneNumbers.append(phoneNumber)
            }
            
            mails.forEach { (mail) in
                let workEmail = CNLabeledValue(label:CNLabelWork, value: mail as NSString)
                cnContact.emailAddresses.append(workEmail)
            }
            
            return cnContact
        }
    }
    
    struct Phone: Rangeable {
        let string: String
        var range: NSRange
    }
    
    struct Mail: Rangeable {
        let string: String
        var range: NSRange
    }
    
    internal func contact() -> Contact? {
        let types: NSTextCheckingResult.CheckingType = [.phoneNumber, .link]
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
                }
            }
            guard contacts.count != 0 else { return nil }
            
            guard contacts.count != 0 else { return nil }
            
            contacts.sort{ $0.range.location > $1.range.location }
            
            var text = self
            var phones: [String] = []
            var mails: [String] = []
            contacts.forEach { (contact) in
                if let phone = contact as? Phone {
                    if let phoneRange = Range(phone.range, in: text) {
                        text.removeSubrange(phoneRange)
                    }
                    phones.append(phone.string)
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
                return Contact(givenName: names.first!, familyName: names.count > 1 ? names.last! : "", phones: phones, mails: mails)
            } else {
                return Contact(givenName: "No Name".loc, familyName: "", phones: phones, mails: mails)
            }
            
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    struct Event {
        let title: String
        let startDate: Date
        let endDate: Date
        
        func createEKEvent(store: EKEventStore) -> EKEvent {
            let ekEvent = EKEvent(eventStore: store)
            ekEvent.title = self.title
            ekEvent.startDate = self.startDate
            ekEvent.endDate = self.endDate
            ekEvent.calendar = store.defaultCalendarForNewEvents
            return ekEvent
        }
    }
    
    internal func event() -> Event? {
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
                            return Event(title: title, startDate: startDate, endDate: endDate)
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
                    return Event(title: text, startDate: startEvent.date, endDate: endEvent.date)
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
                    return Event(title: text, startDate: startEvent.date, endDate: endEvent.date)
                }
            }
            else {
                //두개의 date가 같다면 날짜를 startDate만 입력했다는 말 -> 나머지 range를 제목으로하고 endDate를 한시간 뒤로 하자
                var text = self
                if let startEventRange = Range(startEvent.range, in: text) {
                    text.removeSubrange(startEventRange)
                }
                
                if text.count != 0 {
                    return Event(title: text, startDate: startEvent.date, endDate: startEvent.date.addingTimeInterval(60 * 60))
                }
            }
            
        } catch {
            print("string_extension calendar() 에러: \(error.localizedDescription)")
        }
        
        return nil
    }
}
