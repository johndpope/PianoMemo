//
//  DateComponentFormatter.swift
//  Piano
//
//  Created by Kevin Kim on 04/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

extension DateComponentsFormatter {
    static let sharedInstance: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.calendar = Calendar.current
        formatter.unitsStyle = .abbreviated // May delete the word brief to let Xcode show you the other options
        formatter.allowedUnits = [.day, .hour]
        formatter.maximumUnitCount = 2   // Show just one unit (i.e. 1d vs. 1d 6hrs)
        return formatter
    }()
}
