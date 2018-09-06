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
    @IBOutlet weak var cellButton: UIButton!
    @IBOutlet weak var contentButton: UIButton!
    
    func configure(_ reminder: EKReminder) {
        completeButton.isSelected = reminder.isCompleted
        titleLabel.textColor = reminder.isCompleted ? .lightGray : .black
        titleLabel.text = reminder.title
        dateLabel.text = ""
        if let date = reminder.alarms?.first?.absoluteDate {
            dateLabel.text = DateFormatter.style([.short, .short]).string(from: date)
        }
    }
    
    var cellDidSelected: (() -> ())?
    @IBAction private func action(cell: UIButton) {
        cellDidSelected?()
    }
    
    var contentDidSelected: (() -> ())?
    @IBAction private func action(content: UIButton) {
        contentDidSelected?()
    }
    
}
