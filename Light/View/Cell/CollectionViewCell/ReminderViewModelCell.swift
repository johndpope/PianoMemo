//
//  ReminderCollectionViewCell.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 10..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import EventKitUI

struct ReminderViewModel: CollectionDatable {
    let reminder: EKReminder
    let detailAction: (() -> Void)?
    var sectionTitle: String?
    var sectionImage: Image?
    var sectionIdentifier: String?
    
    init(reminder: EKReminder, detailAction: (() -> Void)? = nil, sectionTitle: String? = nil, sectionImage: Image? = nil, sectionIdentifier: String? = nil) {
        self.reminder = reminder
        self.detailAction = detailAction
        self.sectionTitle = sectionTitle
        self.sectionImage = sectionImage
        self.sectionIdentifier = sectionIdentifier
    }
    
    func didSelectItem(fromVC viewController: ViewController) {
        //TODO: 여기 리마인더 수정하도록 작업하기
        if let detailAction = detailAction {
            detailAction()
        }
    }
    
    func didDeselectItem(fromVC viewController: ViewController) {
        
    }
    
    func size(maximumWidth: CGFloat) -> CGSize {
        return CGSize(width: maximumWidth, height: 73)
    }
    
    var headerSize: CGSize {
        return sectionTitle != nil ? CGSize(width: 100, height: 40) : CGSize(width: 100, height: 0)
    }
    
    var minimumInteritemSpacing: CGFloat = 8
    var minimumLineSpacing: CGFloat = 8
    var sectionInset: EdgeInsets = EdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
}

class ReminderViewModelCell: UICollectionViewCell, CollectionDataAcceptable {
    
    var data: CollectionDatable? {
        didSet {
            guard let viewModel = self.data as? ReminderViewModel else { return }
            
            completeButton.setTitle(Preference.checklistOffValue, for: .normal)
            completeButton.setTitle(Preference.checklistOnValue, for: .selected)
            completeButton.isSelected = viewModel.reminder.isCompleted
            titleLabel.text = viewModel.reminder.title
            if let date = viewModel.reminder.alarms?.first?.absoluteDate {
                dateLabel.isHidden = false
                dateLabel.text = DateFormatter.sharedInstance.string(from: date)
            } else {
                dateLabel.isHidden = true
            }

            if let selectedView = selectedBackgroundView {
                insertSubview(selectedView, aboveSubview: completeButton)
            }
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
        
        guard let viewModel = self.data as? ReminderViewModel else { return }
        viewModel.reminder.isCompleted = sender.isSelected
    }
}
