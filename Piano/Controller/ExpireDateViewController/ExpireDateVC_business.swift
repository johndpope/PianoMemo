//
//  ExpireDateVC_business.swift
//  Piano
//
//  Created by Kevin Kim on 23/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension ExpireDateViewController {
    internal func setup() {
        datePicker.minimumDate = Date()
        datePicker.date = Date()
    }

    internal func setupDataSource() {
        let time1 = ExpireTime(name: "1 hour later".loc,
                               date: Date(timeIntervalSinceNow: 60 * 60))
        let time2 = ExpireTime(name: "6 hour later".loc,
                               date: Date(timeIntervalSinceNow: 60 * 60 * 6))
        let time3 = ExpireTime(name: "Tomorrow".loc,
                               date: Date(timeIntervalSinceNow: 60 * 60 * 24))
        let time4 = ExpireTime(name: "The day after tommorow".loc,
                               date: Date(timeIntervalSinceNow: 60 * 60 * 24 * 2))
        let time5 = ExpireTime(name: "One week later".loc,
                               date: Date(timeIntervalSinceNow: 60 * 60 * 24 * 7))
        let time6 = ExpireTime(name: "One month later".loc,
                               date: Date(timeIntervalSinceNow: 60 * 60 * 24 * 30))
        dataSource.append([time1, time2, time3, time4, time5, time6])
    }
}
