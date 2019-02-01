//
//  NoteCollectionViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 06/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class NoteCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var folderLabel: UILabel!
    @IBOutlet weak var writeNowButtonWidthAnchor: NSLayoutConstraint!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var overlayTitle: UILabel!
    
    var note: Note? {
        didSet {
            guard let note = note else { return }
            titleLabel.text = note.title
            subTitleLabel.text = note.subTitle
            let tags = note.tags?.count != 0 ? note.tags : ""
            folderLabel.text = tags

            if note.isLocked  {
                overlayTitle.text = note.title
                let blurEffect = UIBlurEffect(style: .light)
                let blurEffectView = UIVisualEffectView(effect: blurEffect)
                blurEffectView.frame = overlayView.bounds
                blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                overlayView.insertSubview(blurEffectView, at: 0)
                overlayView.isHidden = false
            }
            
            if let expireDate = note.expireDate {
                dateLabel.textColor = Color.red
                let str = expireDate.dDayStr(sinceDate: Date())
                dateLabel.text = "폭파 시간: \(str)"
            } else {
                dateLabel.textColor = Color.lightGray
                let date = note.modifiedAt as Date? ?? Date()
                dateLabel.text = DateFormatter.sharedInstance.string(from: date)
            }
        }
    }
    weak var noteCollectionVC: NoteCollectionViewController?

    override func awakeFromNib() {
        super.awakeFromNib()
        selectedBackgroundView = customSelectedBackgroudView
    }

}
