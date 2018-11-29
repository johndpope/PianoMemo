//
//  ReminderCell.swift
//  Piano
//
//  Created by Kevin Kim on 28/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import EventKit

class ReminderCell: UITableViewCell {
    
    var ekReminder: EKReminder! {
        didSet {
            titleLabel.text = ekReminder.title
            if let date = ekReminder.alarmDate {
                dateLabel.isHidden = false
                dateLabel.text = DateFormatter.sharedInstance.string(from: date)
            } else {
                dateLabel.isHidden = true
            }
        }
    }
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
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
    
    @IBAction func tapCheck(_ sender: Any) {
        guard let vc = scheduleVC,
            let indexPath = vc.tableView.indexPath(for: self) else { return }
        
        ekReminder.isCompleted = true
        do {
            try vc.eventStore.save(ekReminder, commit: true)
        } catch {
            print(error.localizedDescription)
        }
        
        vc.dataSource[indexPath.section].remove(at: indexPath.row)
        vc.tableView.deleteRows(at: [indexPath], with: .automatic)
    }

}
