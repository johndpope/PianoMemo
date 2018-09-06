//
//  CalendarTableViewCell.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import EventKit

class CalendarTableViewCell: UITableViewCell {

    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var endLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cellButton: UIButton!
    @IBOutlet weak var contentButton: UIButton!
    
    func configure(_ event: EKEvent, isLinked: Bool? = nil) {
        let format = DateFormatter.format("aa h:mm")
        startLabel.text = event.isAllDay ? "하루 종일" : format.string(from: event.startDate)
        endLabel.text = event.isAllDay ? "" : format.string(from: event.endDate)
        titleLabel.text = event.title
        guard let isLinked = isLinked else {return}
        alpha = isLinked ? 0.3 : 1
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
