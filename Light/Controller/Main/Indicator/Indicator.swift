//
//  Indicator.swift
//  Light
//
//  Created by hoemoon on 06/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import EventKit
import Contacts

struct Indicator {
    enum IndicatorType: String {
        case reminder
        case contact
        case event
    }
    let date = Date()
    let type: IndicatorType

    let reminder: EKReminder?
    let contact: CNContact?
    let event: EKEvent?

    init(type: IndicatorType,
         reminder: EKReminder? = nil,
         contact: CNContact? = nil,
         event: EKEvent? = nil) {

        self.type = type
        self.reminder = reminder
        self.contact = contact
        self.event = event
    }
}

extension Indicator: Hashable {
    var hashValue: Int {
        return date.hashValue
    }

    static func == (lhs: Indicator, rhs: Indicator) -> Bool {
        return lhs.date == rhs.date
    }
}

extension Indicator {
    private var font: UIFont {
        return UIFont.preferredFont(forTextStyle: .body)
    }

    var headerAttribute: [NSAttributedString.Key: Any] {
        var dict = [NSAttributedString.Key: Any]()
        dict[.foregroundColor] = UIColor(red:0.60, green:0.60, blue:0.60, alpha:1.00)
        dict[.font] = font
        return dict
    }

    var bodyAttribute: [NSAttributedString.Key: Any] {
        var dict = [NSAttributedString.Key: Any]()
        dict[.foregroundColor] = UIColor(red:0.37, green:0.58, blue:0.93, alpha:1.00)
        dict[.font] = font
        return dict
    }

    var attrbutedString: NSAttributedString {
        switch self.type {
        case .reminder:
            if let reminder = reminder {
                let header = NSMutableAttributedString(string: reminder.title.trimmingCharacters(in: .whitespaces), attributes: headerAttribute)
                if let alarmDate = reminder.alarmDate {
                    let string = DateFormatter.sharedInstance.string(from: alarmDate)
                    header.append(NSAttributedString(string: "\n\(string)", attributes: bodyAttribute))
                }
                
                return header
            }
        case .contact:
            if let contact = contact {
                // TODO: 성과 이름의 순서
                let header = NSMutableAttributedString(
                    string: "\(contact.givenName.trimmingCharacters(in: .whitespaces)) \(contact.familyName.trimmingCharacters(in: .whitespaces))",
                    attributes: headerAttribute)
                contact.phoneNumbers.forEach {
                    header.append(NSAttributedString(string: "\n\($0.value.stringValue)", attributes: bodyAttribute))
                    
                }                
                contact.emailAddresses.forEach {
                    header.append(NSAttributedString(string: "\n\($0.value)", attributes: bodyAttribute))
                }

                return header
            }
        case .event:
            if let event = event {
                let header = NSMutableAttributedString(string: event.title.trimmingCharacters(in: .whitespaces), attributes: headerAttribute)
                let start = DateFormatter.sharedInstance.string(from: event.startDate)
                let end = DateFormatter.sharedInstance.string(from: event.endDate)
                header.append(NSAttributedString(string: "\n\(start)", attributes: bodyAttribute))
                header.append(NSAttributedString(string: "\n\(end)", attributes: bodyAttribute))
                return header
            }
        }
        return NSAttributedString()
    }

    var expectedHeight: CGFloat {
        var height:CGFloat = 0
        let fontHeight = font.lineHeight
        let contentViewMargin: CGFloat = 8

        switch self.type {
        case .reminder:
            height = 2 * fontHeight
        case .contact:
            if let contact = contact {
                var count:CGFloat = 1
                if contact.emailAddresses.count > 0 {
                    count += 1
                }
                if contact.phoneNumbers.count > 0 {
                    count += 1
                }
                height = count * fontHeight
            }
        case .event:
            height = 3 * fontHeight
        }
        return height + contentViewMargin * 2
    }
}
