//
//  ReminderCollectionViewCell.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 10..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import EventKit

extension EKReminder: CollectionDatable {
    var sectionImage: Image? { return #imageLiteral(resourceName: "suggestionsReminder") }
    var sectionTitle: String? { return "Reminder".loc }
    var headerSize: CGSize { return CGSize(width: 100, height: 40) }
    
    internal func size(view: View) -> CGSize {
        let safeWidth = view.bounds.width - (view.safeAreaInsets.left + view.safeAreaInsets.right)
        let titleHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .body)]).size().height
        let dateHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .caption2)]).size().height
        let margin: CGFloat = 8 * 2
        let totalHeight = titleHeight + dateHeight + margin
        if safeWidth > 414 {
            var cellCount: CGFloat = 3
            let widthOne = safeWidth / cellCount
            if widthOne > 320 {
                return CGSize(width: widthOne, height: totalHeight)
            }
            
            cellCount = 2
            let widthTwo = safeWidth / cellCount
            if widthTwo > 320 {
                return CGSize(width: widthTwo, height: totalHeight)
            }
        }
        
        return CGSize(width: safeWidth, height: totalHeight)
    }
}

class EKReminderCell: UICollectionViewCell, CollectionDataAcceptable {
    
    var data: CollectionDatable? {
        didSet {
            guard let ekReminder = self.data as? EKReminder else { return }
            
            completeButton.setTitle(Preference.checklistOffValue, for: .normal)
            completeButton.setTitle(Preference.checklistOnValue, for: .selected)
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
        selectedBackgroundView = borderView
    }
    
    var borderView: UIView {
        let view = UIView()
        view.backgroundColor = Color.clear
        view.cornerRadius = 15
        view.borderWidth = 2
        view.borderColor = Color(red: 62/255, green: 154/255, blue: 255/255, alpha: 0.8)
        return view
    }
    
    @IBAction func reminder(_ sender: Button) {
        sender.isSelected = !sender.isSelected
        
        guard let ekReminder = self.data as? EKReminder else { return }
        ekReminder.isCompleted = sender.isSelected
        changeTitleAttr(isSelected: sender.isSelected)
        
    }
    
    private func changeTitleAttr(isSelected: Bool) {
        let eventStore = EKEventStore()
        guard let text = titleLabel.text,
            let reminder = data as? EKReminder, let ekReminder = eventStore.calendarItems(withExternalIdentifier: reminder.calendarItemExternalIdentifier).first as? EKReminder else { return }
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
