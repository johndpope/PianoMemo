//
//  EventCollectionViewCell.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 10..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import EventKit
import EventKitUI

struct EventViewModel: CollectionDatable {
    let event: EKEvent
    let detailAction: (() -> Void)?
    var sectionTitle: String?
    var sectionIdentifier: String?
    var sectionImage: Image?
    
    init(event: EKEvent, detailAction: (() -> Void)? = nil, sectionTitle: String? = nil, sectionImage : Image? = nil, sectionIdentifier: String? = nil) {
        self.event = event
        self.detailAction = detailAction
        self.sectionTitle = sectionTitle
        self.sectionImage = sectionImage
        self.sectionIdentifier = sectionIdentifier
    }
    
    func didSelectItem(fromVC viewController: ViewController) {
        if detailAction == nil {
            viewController.performSegue(withIdentifier: EventDetailViewController.identifier, sender: self.event)
        }
    }
    
    func didDeselectItem(fromVC viewController: ViewController) {
        
    }
    
    func size(maximumWidth: CGFloat) -> CGSize {
        return detailAction != nil ? CGSize(width: maximumWidth, height: 103) : CGSize(width: maximumWidth, height: 73)
    }
    
    var headerSize: CGSize {
        return sectionTitle != nil ? CGSize(width: 100, height: 40) : CGSize(width: 100, height: 0)
    }
    var sectionInset: EdgeInsets = EdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    var minimumInteritemSpacing: CGFloat = 8
    var minimumLineSpacing: CGFloat = 8
    
}

class EventViewModelCell: UICollectionViewCell, CollectionDataAcceptable {
    
    var data: CollectionDatable? {
        didSet {
            guard let viewModel = self.data as? EventViewModel else { return }
            titleLabel.text = viewModel.event.title
            startDateLabel.text = DateFormatter.sharedInstance.string(from: viewModel.event.startDate)
            endDateLabel.text = DateFormatter.sharedInstance.string(from: viewModel.event.endDate)
            if let integer = Date().days(sinceDate: viewModel.event.startDate) {
                if integer > 0 {
                    dDayLabel.text = "D+\(integer)"
                } else if integer == 0 {
                    dDayLabel.text = "D-\(integer)"
                } else {
                    dDayLabel.text = "D\(integer)"
                }
            }
            
            if let selectedView = selectedBackgroundView {
                insertSubview(selectedView, aboveSubview: detailButton)
            }
            detailButton.isHidden = viewModel.detailAction == nil
        }
    }
    
    @IBOutlet weak var dDayLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var detailButton: UIButton!
    
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
    
    @IBAction func detail(_ sender: Any) {
        guard let viewModel = self.data as? EventViewModel,
            let detailAction = viewModel.detailAction else { return }
        detailAction()
    }
}
