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
    let infoAction: (() -> Void)?
    var sectionTitle: String?
    var sectionIdentifier: String?
    var sectionImage: Image?
    
    init(event: EKEvent, infoAction: (() -> Void)? = nil, sectionTitle: String? = nil, sectionImage : Image? = nil, sectionIdentifier: String? = nil) {
        self.event = event
        self.infoAction = infoAction
        self.sectionTitle = sectionTitle
        self.sectionImage = sectionImage
        self.sectionIdentifier = sectionIdentifier
    }
    
    func didSelectItem(fromVC viewController: ViewController) {
        if infoAction == nil {
            let eventVC = EKEventViewController()
            eventVC.allowsEditing = false
            eventVC.event = self.event
            viewController.navigationController?.pushViewController(eventVC, animated: true)
        }
    }
    
    func didDeselectItem(fromVC viewController: ViewController) {
        
    }
    
    func size(maximumWidth: CGFloat) -> CGSize {
        return CGSize(width: maximumWidth, height: 120)
    }
    
    var headerSize: CGSize {
        return CGSize(width: 100, height: 30)
    }
    
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
            dDayLabel.text = "TODO"
            
            infoButton.isHidden = viewModel.infoAction == nil
            
            if let selectedView = selectedBackgroundView,
                let viewModel = data as? EventViewModel,
                viewModel.infoAction != nil {
                insertSubview(selectedView, aboveSubview: infoButton)
            }
            
            descriptionView.isHidden = viewModel.sectionIdentifier != nil
        }
    }
    
    @IBOutlet weak var dDayLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var descriptionView: UIView!
    
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
    
    @IBAction func info(_ sender: Any) {
        guard let viewModel = self.data as? EventViewModel,
            let infoAction = viewModel.infoAction else { return }
        infoAction()
    }
}
