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
            NSLinguisticTagger.availableTagSchemes(forLanguage: language).contains(.lexicalClass),
            self.count > 3 {
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
        let noTrash = NSPredicate(format: "isRemoved == false")
        var predicates = Set(tokens)
            .map { NSPredicate(format: "\(searchField) contains[cd] %@", $0) }
        guard predicates.count > 0 else { return noTrash }
        
        predicates.append(noTrash)
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}


extension String {
    //issue: 문제있음
//    func substring(with range: NSRange) -> String {
//        let substring = self[self.index(self.startIndex, offsetBy: range.lowerBound) ..< self.index(self.startIndex, offsetBy: range.upperBound)]
//        return String(substring)
//    }
}



extension String {
    //변환해주는 건 아래꺼를 쓰면 된다.
    internal func createFormatAttrString(fromPasteboard: Bool) -> NSMutableAttributedString {
    
        var range = NSMakeRange(0, 0)
        let mutableAttrString = NSMutableAttributedString(string: self, attributes: Preference.defaultAttr)
        while true {
            guard range.location < mutableAttrString.length else { break }
            
            let paraRange = (mutableAttrString.string as NSString).paragraphRange(for: range)
            range.location = paraRange.location + paraRange.length + 1
            
            if let bulletKey = BulletKey(text: mutableAttrString.string, selectedRange: paraRange) {
                range.location += mutableAttrString.transform(bulletKey: bulletKey)
                continue
            }
            
            if fromPasteboard {
                if let bulletValue = BulletValue(textFromPasteboard: mutableAttrString.string, selectedRange: paraRange) {
                    range.location += mutableAttrString.transform(bulletValue: bulletValue)
                    continue
                }
            }
            
        }
        return mutableAttrString
    }
}

protocol Rangeable {
    var range: NSRange { get set }
}

protocol Recommandable {
}

extension EKEvent: Recommandable {}
extension EKReminder: Recommandable {}
extension CNContact: Recommandable {}

//MARK: link Data
extension String {
    internal var recommandData: Recommandable? {
        let store = EKEventStore()
        if let reminder = self.reminder(store: store) {
            return reminder
        } else if let event = self.event(store: store) {
            return event
        } else if let address = self.address() {
            return address
        } else if let contact = self.contact() {
            return contact
        } else {
            return nil
        }
    }
    
    internal func reminder(store: EKEventStore) -> EKReminder? {
        do {
            let regex = try NSRegularExpression(pattern: "^\\s*(\\S+)(?= )", options: .anchorsMatchLines)
            let searchRange = NSMakeRange(0, count)
            
            guard let result = regex.matches(in: self, options: .withTransparentBounds, range: searchRange).first else { return nil }
            let range = result.range(at: 1)
            let nsString = self as NSString
            let string = nsString.substring(with: range)
            if string == Preference.checklistOffValue || string == Preference.checklistOnValue {
                let contentString = nsString.substring(from: range.upperBound + 1)
                
                guard let event = contentString.event(store: store) else { return nil }
                
                let reminder = EKReminder(eventStore: store)
                reminder.title = event.title
                reminder.addAlarm(EKAlarm(absoluteDate: event.startDate))
                reminder.isCompleted = string != Preference.checklistOffValue
                reminder.calendar = store.defaultCalendarForNewReminders()
                return reminder
            }
            
        } catch {
            print("string_extension reminder() 에러: \(error.localizedDescription)")
        }
        return nil
    }
    
    func combineDateWithTime(date: Date, time: Date) -> Date? {
        let calendar = Calendar.current
        
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var mergedComponments = DateComponents()
        mergedComponments.year = dateComponents.year
        mergedComponments.month = dateComponents.month
        mergedComponments.day = dateComponents.day
        mergedComponments.hour = timeComponents.hour
        mergedComponments.minute = timeComponents.minute
        
        return calendar.date(from: mergedComponments)
    }
    
    internal func event(store: EKEventStore) -> EKEvent? {
        guard reminder(store: store) == nil else { return nil }
        
        let types: NSTextCheckingResult.CheckingType = [.date]
        do {
            let detector = try NSDataDetector(types:types.rawValue)
            let searchRange = NSMakeRange(0, count)
            
            let matches = detector.matches(in: self, options: .reportCompletion, range: searchRange)
            guard matches.count != 0 else { return nil }
            //duration이 존재한다면 그 자체가 일정이므로 곧바로 이벤트를 만들고 나머지를 텍스트로 하여 리턴한다.
            let durationMatches = matches.filter{ $0.duration != 0 }
            if let firstDurationMatch = durationMatches.first,
                var startDate = firstDurationMatch.date {
                //현재보다 이전 시간이라면 다음 날짜로 등록
                if Date() > startDate {
                    startDate.addTimeInterval(60 * 60 * 24)
                }
                let endDate = startDate.addingTimeInterval(firstDurationMatch.duration)
                let calendar = store.defaultCalendarForNewEvents
                var title = self
                if let dateRange = Range(firstDurationMatch.range,  in: title) {
                    title.removeSubrange(dateRange)
                }
                
                let event = EKEvent(eventStore: store)
                event.title = title
                event.startDate = startDate
                event.endDate = endDate
                event.calendar = calendar
                return event
            } else {
                
                let eventInfos = matches.compactMap { (result) -> (Date, NSRange)? in
                    guard let date = result.date else { return nil }
                    return (date, result.range)
                }
                //1개라면 바로 추가
                if eventInfos.count == 1 {
                    let (date, range) = eventInfos.first!
                    let startDate = Date() > date ? date.addingTimeInterval(60 * 60 * 24) : date
                    let endDate = startDate.addingTimeInterval(60 * 60)
                    let calendar = store.defaultCalendarForNewEvents
                    var title = self
                    if let dateRange = Range(range,  in: title) {
                        title.removeSubrange(dateRange)
                    }
                    let event = EKEvent(eventStore: store)
                    event.title = title
                    event.startDate = startDate
                    event.endDate = endDate
                    event.calendar = calendar
                    return event
                    
                } else {
                    //2개 이상이라면 가장 이른 시간으로 일정 잡자!
                    let sortedEventInfos = eventInfos.sorted { (leftInfo, rightInfo) -> Bool in
                        return leftInfo.0 < rightInfo.0
                    }
                    let (date, range) = sortedEventInfos.first!
                    let startDate = Date() > date ? date.addingTimeInterval(60 * 60 * 24) : date
                    let endDate = startDate.addingTimeInterval(60 * 60)
                    let calendar = store.defaultCalendarForNewEvents
                    var title = self
                    if let dateRange = Range(range,  in: title) {
                        title.removeSubrange(dateRange)
                    }
                    let event = EKEvent(eventStore: store)
                    event.title = title
                    event.startDate = startDate
                    event.endDate = endDate
                    event.calendar = calendar
                    return event
                }
            }
        } catch {
            print("string_extension calendar() 에러: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    private struct Phone: Rangeable {
        let string: String
        var range: NSRange
    }
    
    private struct Mail: Rangeable {
        let string: String
        var range: NSRange
    }
    
    private struct Address: Rangeable {
        let string: String
        var range: NSRange
    }
    
    internal func address() -> CNMutableContact? {
        let eventStore = EKEventStore()
        guard reminder(store: eventStore) == nil && event(store: eventStore) == nil else { return nil }
        let types: NSTextCheckingResult.CheckingType = [.address]
        do {
            let detector = try NSDataDetector(types: types.rawValue)
            let searchRange = NSMakeRange(0, count)
            
            guard let match = detector.firstMatch(in: self, options: .reportCompletion, range: searchRange),
                let addressComponents = match.addressComponents else { return nil }
            
            let cnMutableContact = CNMutableContact()
            let address = CNMutablePostalAddress()
            
            var text = self
            if let range = Range(match.range, in: text) {
                text.removeSubrange(range)
            }
            //TODO: 불안한 로직(우편번호가 디텍트되지 않아서 여기서 숫자만 있을 때 우편번호라 가정하고 걸러냄, 가정한 이유는 위치 버튼을 누르면 우편번호까지 같이 디텍팅되기 때문
            let trimText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if Int(trimText) != nil {
                address.postalCode = trimText
            } else if trimText.count != 0 {
                cnMutableContact.givenName = text
            }

            addressComponents.forEach { (key, value) in
                if key.rawValue == "Street" {
                    address.street = value
                } else if key.rawValue == "City" {
                    address.city = value
                } else if key.rawValue == "State" {
                    address.state = value
                } else if key.rawValue == "PostalCode" {
                    address.postalCode = value
                } else if key.rawValue == "Country" {
                    address.country = value
                } else if key.rawValue == "IsoCountryCode" {
                    address.isoCountryCode = value
                }
            }
            let postalAddresses = CNLabeledValue<CNPostalAddress>(label:CNLabelHome, value:address)
            cnMutableContact.postalAddresses = [postalAddresses]
            
            

            
            return cnMutableContact
            
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    internal func contact() -> CNMutableContact? {
        let eventStore = EKEventStore()
        guard reminder(store: eventStore) == nil && event(store: eventStore) == nil else { return nil }
        
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
            
            if text.trimmingCharacters(in: .whitespacesAndNewlines).count != 0 {
                let allName = text.components(separatedBy: .whitespacesAndNewlines)
                let names = allName.filter { $0.count != 0 }
                
                let cnContact = CNMutableContact()
                cnContact.givenName = names.first ?? "No name".loc
                cnContact.familyName = names.count > 1 ? names.last! : ""
                
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
                
            } else {
                
                
                let cnContact = CNMutableContact()
                cnContact.givenName = "No name".loc
                cnContact.familyName = ""
                
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
            
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
}

extension String.SubSequence {
    mutating func removeCharacters(strings: [String]) {
        strings.forEach {
            while true {
                guard let range = self.range(of: $0) else { break }
                self.removeSubrange(range)
            }
        }
    }
}

extension String {
    mutating func removeCharacters(strings: [String]) {
        strings.forEach {
            while true {
                guard let range = self.range(of: $0) else { break }
                self.removeSubrange(range)
            }
        }
    }
}


extension EKReminder {
    var alarmDate: Date? {
        return alarms?.first?.absoluteDate
    }
}

extension String {
    func detectedLangauge() -> String? {
        guard let languageCode = NSLinguisticTagger.dominantLanguage(for: self) else {
            return nil
        }
        
        let detectedLangauge = Locale.current.localizedString(forIdentifier: languageCode)
        
        return detectedLangauge
    }
}

extension String {
    var titles: (String, String) {
        var strArray = self.split(separator: "\n")
        guard strArray.count != 0 else {
            return ("Untitled".loc, "No text".loc)
        }
        let titleSubstring = strArray.removeFirst()
        var titleString = String(titleSubstring)
        titleString.removeCharacters(strings: Preference.allKeys)
        let titleLimit = 50
        if titleString.count > titleLimit {
            titleString = (titleString as NSString).substring(with: NSMakeRange(0, titleLimit))
        }


        var subTitleString: String = ""
        while true {
            guard strArray.count != 0 else { break }

            let pieceSubString = strArray.removeFirst()
            var pieceString = String(pieceSubString)
            pieceString.removeCharacters(strings: Preference.allKeys)
            subTitleString.append(pieceString)
            let titleLimit = 50
            if subTitleString.count > titleLimit {
                subTitleString = (subTitleString as NSString).substring(with: NSMakeRange(0, titleLimit))
                break
            }
        }

        return (titleString, subTitleString.count != 0 ? subTitleString : "No text".loc)    }
}

