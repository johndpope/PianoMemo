//
//  Indicator.swift
//  Light
//
//  Created by hoemoon on 06/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

struct Indicator {
    enum IndicatorType: String {
        case reminder
        case contact
        case event
    }
    let date = Date()
    let type: IndicatorType

    let reminder: String.Reminder?
    let contact: String.Contact?
    let event: String.Event?

    init(type: IndicatorType,
         reminder: String.Reminder? = nil,
         contact: String.Contact? = nil,
         event: String.Event? = nil) {

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
                if let event = reminder.event {
                    let string = DateFormatter.sharedInstance.string(from: event.startDate)
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
                if contact.phones.count > 0 {
                    header.append(NSAttributedString(string: "\n\(contact.phones.first!)", attributes: bodyAttribute))
                }
                if contact.mails.count > 0 {
                    header.append(NSAttributedString(string: "\n\(contact.mails.first!)", attributes: bodyAttribute))
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
            if let reminder = reminder {
                if let _ = reminder.event {
                    height = 2 * fontHeight
                } else {
                    height = 1 * fontHeight
                }
            }
        case .contact:
            if let contact = contact {
                var count:CGFloat = 1
                if contact.mails.count > 0 {
                    count += 1
                }
                if contact.phones.count > 0 {
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
