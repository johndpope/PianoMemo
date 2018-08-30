//
//  ReminderRecommendCell.swift
//  Light
//
//  Created by hoemoon on 30/08/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import EventKit

class ReminderRecommendCell: UITableViewCell {
    static let identifier = "ReminderRecommendCell"

    func configure(_ reminder: EKReminder) {
        self.textLabel?.text = reminder.title
    }
}
