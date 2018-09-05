//
//  IndicatorCell.swift
//  Light
//
//  Created by hoemoon on 05/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class IndicatorCell: UITableViewCell {

    func configure(_ indicator: Indicator) {
        selectionStyle = .none
        backgroundColor = .clear
        textLabel?.text = indicator.title
        switch indicator.type {
        case .calendar:
            print("calendar")
        case .contact:
            print("contact")
        case .reminder:
            print("reminder")
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        textLabel?.text = ""
    }
}
