//
//  EventCell.swift
//  Piano
//
//  Created by Kevin Kim on 28/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import EventKit

class EventCell: UITableViewCell {

    var ekEvent: EKEvent! {
        didSet {
            titleLabel.text = ekEvent.title
            startDateLabel.text = DateFormatter.sharedInstance.string(from: ekEvent.startDate)
            endDateLabel.text = DateFormatter.sharedInstance.string(from: ekEvent.endDate)
            
            if let eventDate = ekEvent.startDate {
                var dDayString = eventDate.dDay
                if dDayString.contains("-") {
                    dDayString.removeCharacters(strings: ["-"])
                    self.dDayLabel.text = "\(dDayString) " + "ago".loc
                } else {
                    self.dDayLabel.text = "\(dDayString) " + "left".loc
                }
            }
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var dDayLabel: UILabel!
    weak var scheduleVC: ScheduleViewController?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectedBackgroundView = customSelectedBackgroudView
    }
    
    var customSelectedBackgroudView: UIView {
        let view = UIView()
        view.backgroundColor = Color(red: 153/255, green: 199/255, blue: 255/255, alpha: 0.3)
        return view
    }

}
