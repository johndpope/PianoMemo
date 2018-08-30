//
//  ReminderSuggestionCell.swift
//  Light
//
//  Created by hoemoon on 30/08/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import EventKit

class ReminderSuggestionCell: UITableViewCell {
    static let identifier = "ReminderSuggestionCell"

    func configure(_ reminder: EKReminder) {
        textLabel?.text = reminder.title
        contentView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        contentView.layer.cornerRadius = 5
        selectionStyle = .none
    }
}
