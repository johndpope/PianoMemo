//
//  DateFormatter.swift
//  Block
//
//  Created by Kevin Kim on 2018. 7. 12..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation

extension DateFormatter {
    static let sharedInstance: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
}
