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
    //action이 있다면, 액션으로 디테일을 들어간고, 액션 버튼이 없다면, didSelect에서 들어간다.
    let infoAction: (() -> Void)?
    var sectionTitle: String?
    var sectionImage: Image?
    var sectionIdentifier: String?
    
    
    init(reminder: EKReminder, infoAction: (() -> Void)? = nil, sectionTitle: String? = nil, sectionImage: Image? = nil, sectionIdentifier: String? = nil) {
        self.reminder = reminder
        self.infoAction = infoAction
        self.sectionTitle = sectionTitle
        self.sectionImage = sectionImage
        self.sectionIdentifier = sectionIdentifier
    }
    
    func didSelectItem(fromVC viewController: ViewController) {
        
    }
    
    func didDeselectItem(fromVC viewController: ViewController) {
        
    }
    
    func size(maximumWidth: CGFloat) -> CGSize {
        return sectionIdentifier != nil ? CGSize(width: maximumWidth, height: 73) : CGSize(width: maximumWidth, height: 103)
    }
    
    var headerSize: CGSize {
        return CGSize(width: 100, height: 33)
    }
    
    var minimumInteritemSpacing: CGFloat = 8
    var minimumLineSpacing: CGFloat = 8
    var sectionInset: EdgeInsets = EdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
}

class ReminderViewModelCell: UICollectionViewCell, CollectionDataAcceptable {
    
    var data: CollectionDatable? {
        didSet {
            guard let viewModel = self.data as? ReminderViewModel else { return }
            completeButton.isSelected = viewModel.reminder.isCompleted
            titleLabel.text = viewModel.reminder.title
            if let date = viewModel.reminder.alarms?.first?.absoluteDate {
                dateLabel.isHidden = false
                dateLabel.text = DateFormatter.sharedInstance.string(from: date)
            } else {
                dateLabel.isHidden = true
            }

            if let selectedView = selectedBackgroundView,
                let viewModel = data as? ReminderViewModel,
                viewModel.infoAction != nil {
                insertSubview(selectedView, aboveSubview: infoButton)
            }
            
            infoButton.isHidden = viewModel.infoAction == nil
            descriptionView.isHidden = viewModel.sectionIdentifier != nil
        }
    }
    
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var descriptionView: UIView!
    
    @IBAction func info(_ sender: Any) {
    }
    
    
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
}
