//
//  ReminderTableViewCell.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import EventKit

class ReminderTableViewCell: UITableViewCell {

    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    func configure(_ reminder: EKReminder, isLinked: Bool? = nil) {
        completeButton.isSelected = reminder.isCompleted
        titleLabel.text = reminder.title
        dateLabel.text = ""
        if let date = reminder.alarms?.first?.absoluteDate {
            dateLabel.text = DateFormatter.style([.short, .short]).string(from: date)
        }
        guard let isLinked = isLinked else {return}
        alpha = isLinked ? 0.3 : 1
    }

}
