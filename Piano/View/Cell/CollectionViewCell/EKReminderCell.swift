//
//  ReminderCollectionViewCell.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 10..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import EventKit

extension EKReminder: Collectionable {
    internal func size(view: View) -> CGSize {
        let width = view.bounds.width
        let titleHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .body)]).size().height
        let dateHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .caption2)]).size().height
        let margin: CGFloat = minimumInteritemSpacing
        let totalHeight = titleHeight + dateHeight + margin * 2
        var cellCount: CGFloat = 3
        if width > 414 {
            let widthOne = (width - (cellCount + 1) * margin) / cellCount
            if widthOne > 320 {
                return CGSize(width: widthOne, height: totalHeight)
            }
            
            cellCount = 2
            let widthTwo = (width - (cellCount + 1) * margin) / cellCount
            if widthTwo > 320 {
                return CGSize(width: widthTwo, height: totalHeight)
            }
        }
        cellCount = 1
        return CGSize(width: (width - (cellCount + 1) * margin), height: totalHeight)
    }
}

struct ReminderViewModel: ViewModel {
    let ekReminder: EKReminder
    init(ekReminder: EKReminder) {
        self.ekReminder = ekReminder
    }
} 

class EKReminderCell: UICollectionViewCell, ViewModelAcceptable {
    var viewModel: ViewModel? {
        didSet {
            guard let reminderViewModel = self.viewModel as? ReminderViewModel else { return }
            let ekReminder = reminderViewModel.ekReminder
            completeButton.setTitle("❎", for: .normal)
            completeButton.setTitle("✅", for: .selected)
            completeButton.isSelected = ekReminder.isCompleted
            titleLabel.text = ekReminder.title
            if let date = ekReminder.alarms?.first?.absoluteDate {
                dateLabel.isHidden = false
                dateLabel.text = DateFormatter.sharedInstance.string(from: date)
            } else {
                dateLabel.isHidden = true
            }
            changeTitleAttr(isSelected: completeButton.isSelected)
        }
    }
    
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        selectedBackgroundView = customSelectedBackgroudView
    }
    
    var customSelectedBackgroudView: UIView {
        let view = UIView()
        view.backgroundColor = Color.selected
        view.cornerRadius = 15
        return view
    }
    
    @IBAction func reminder(_ sender: Button) {
        sender.isSelected = !sender.isSelected
        guard let reminderViewModel = viewModel as? ReminderViewModel else { return }
        let ekReminder = reminderViewModel.ekReminder
        ekReminder.isCompleted = sender.isSelected
        changeTitleAttr(isSelected: sender.isSelected)
        Feedback.success()
        
    }
    
    private func changeTitleAttr(isSelected: Bool) {
        let eventStore = EKEventStore()
        guard let text = titleLabel.text,
            let reminderViewModel = viewModel as? ReminderViewModel,
            let ekReminder = eventStore.calendarItems(withExternalIdentifier: reminderViewModel.ekReminder.calendarItemExternalIdentifier).first as? EKReminder else { return }
        ekReminder.isCompleted = isSelected
        
        if isSelected {
            let attrText = NSAttributedString(string: text, attributes: Preference.strikeThroughAttr)
            titleLabel.attributedText = attrText
        } else {
            let attrText = NSAttributedString(string: text, attributes: Preference.defaultAttr)
            titleLabel.attributedText = attrText
        }
        
        do {
            try eventStore.save(ekReminder, commit: true)
        } catch {
            print("changeTitleAttr에서 에러: \(error.localizedDescription)")
        }
        
    }
}
