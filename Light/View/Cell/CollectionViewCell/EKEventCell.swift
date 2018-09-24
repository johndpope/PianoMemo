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

extension EKEvent: CollectionDatable {
    var sectionImage: Image? { return #imageLiteral(resourceName: "suggestionsCalendar") }
    var sectionTitle: String? { return "Calendar".loc }
    var headerSize: CGSize { return CGSize(width: 100, height: 40) }
    
    internal func size(view: View) -> CGSize {
        let safeWidth = view.bounds.width - (view.safeAreaInsets.left + view.safeAreaInsets.right)
        let titleHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .body)]).size().height
        let startDateHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .caption2)]).size().height
        let endDateHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .caption2)]).size().height
        let margin: CGFloat = 16 * 2
        let spacing: CGFloat = 4 * 2
        let totalHeight = titleHeight + startDateHeight + endDateHeight + margin + spacing
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
    
    func didSelectItem(collectionView: CollectionView, fromVC viewController: ViewController) {
        viewController.performSegue(withIdentifier: EventDetailViewController.identifier, sender: self)
    }
}

class EKEventCell: UICollectionViewCell, CollectionDataAcceptable {
    
    var data: CollectionDatable? {
        didSet {
            guard let event = self.data as? EKEvent else { return }
            titleLabel.text = event.title
            startDateLabel.text = DateFormatter.sharedInstance.string(from: event.startDate)
            endDateLabel.text = DateFormatter.sharedInstance.string(from: event.endDate)
            if let integer = Date().days(sinceDate: event.startDate) {
                if integer > 0 {
                    dDayLabel.text = "D+\(integer)"
                } else if integer == 0 {
                    dDayLabel.text = "soon".loc
                } else {
                    dDayLabel.text = "D\(integer)"
                }
            }
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
}
