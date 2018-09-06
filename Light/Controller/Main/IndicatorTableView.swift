//
//  IndicatorTableView.swift
//  Light
//
//  Created by hoemoon on 05/09/2018.
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

    var headerAttribute: [NSAttributedStringKey: Any] {
        var dict = [NSAttributedStringKey: Any]()
        dict[.foregroundColor] = UIColor.black
        dict[.font] = font
        return dict
    }

    var bodyAttribute: [NSAttributedStringKey: Any] {
        var dict = [NSAttributedStringKey: Any]()
        dict[.foregroundColor] = UIColor.blue
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
        let margin: CGFloat = 16

        switch self.type {
        case .reminder:
            if let reminder = reminder {
                if let _ = reminder.event {
                    height = 2 * fontHeight
                }
                height = 1 * fontHeight
            }
        case .contact:
            if let contact = contact {
                var count:CGFloat = 1
                if contact.mails.count > 0 {
                    count += 1
                }
                if contact.phones.count > 1 {
                    count += 1
                }
                height = count * fontHeight
            }
        case .event:
            height = 3 * fontHeight
        }
        return height + margin
    }
}

class IndicatorTableView: UITableView {
    private var indicators = [Indicator]()
    override func awakeFromNib() {
        super.awakeFromNib()
        dataSource = self
        separatorStyle = .none
        backgroundColor = .none
        rowHeight = UITableViewAutomaticDimension
        estimatedRowHeight = 50
        isScrollEnabled = false
    }

    func refresh(_ newIndicators: [Indicator]) {
        self.indicators = newIndicators
            .sorted { $0.date < $1.date }
        reloadData()
    }
}

extension IndicatorTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return indicators.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "IndicatorCell", for: indexPath) as? IndicatorCell {
            cell.configure(indicators[indexPath.row])
            return cell
        }
        return UITableViewCell()
    }

}
