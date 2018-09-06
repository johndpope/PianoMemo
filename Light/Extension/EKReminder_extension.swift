//
//  EKEvent_extension.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 6..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import EventKit

extension EKReminder {
    internal func modify(to reminderDetected: String.Reminder) {
        self.title = reminderDetected.title
        var alarms: [EKAlarm] = []
        if let startDate = reminderDetected.event?.startDate {
            alarms.append(EKAlarm(absoluteDate: startDate))
        }
        self.alarms = alarms
        self.isCompleted = reminderDetected.isCompleted
    }
}
