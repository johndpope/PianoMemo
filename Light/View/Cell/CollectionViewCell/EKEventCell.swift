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

extension EKEvent: Collectionable {
    internal func size(view: View) -> CGSize {
        let width = view.bounds.width
        let titleHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .body)]).size().height
        let startDateHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .caption2)]).size().height
        let endDateHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .caption2)]).size().height
        let margin: CGFloat = minimumInteritemSpacing
        let spacing: CGFloat = 4
        let totalHeight = titleHeight + startDateHeight + endDateHeight + margin * 2 + spacing * 2
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
    
    func didSelectItem(collectionView: CollectionView, fromVC viewController: ViewController) {
        viewController.performSegue(withIdentifier: EventDetailViewController.identifier, sender: self)
    }
}

struct EventViewModel: ViewModel {
    let ekEvent: EKEvent
    init(ekEvent: EKEvent) {
        self.ekEvent = ekEvent
    }
}

class EKEventCell: UICollectionViewCell, ViewModelAcceptable {
    var viewModel: ViewModel? {
        didSet {
            guard let eventViewModel = self.viewModel as? EventViewModel else { return }
            let event = eventViewModel.ekEvent
            titleLabel.text = event.title
            startDateLabel.text = DateFormatter.sharedInstance.string(from: event.startDate)
            endDateLabel.text = DateFormatter.sharedInstance.string(from: event.endDate)
            dDayLabel.text = event.startDate.dDay
        }
    }
    
    @IBOutlet weak var dDayLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var detailButton: UIButton!
    
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
}
