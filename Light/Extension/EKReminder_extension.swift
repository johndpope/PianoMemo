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
        self.title = reminderDetected.event.title
        self.alarms = [EKAlarm(absoluteDate: reminderDetected.event.startDate)]
        self.isCompleted = reminderDetected.isCompleted
    }
}
