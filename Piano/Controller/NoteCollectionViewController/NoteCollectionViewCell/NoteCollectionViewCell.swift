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
    @IBOutlet weak var writeNowButton: UIButton!
    weak var noteCollectionVC: NoteCollectionViewController?
    @IBOutlet weak var overlayTitle: UILabel!
    @IBOutlet weak var overlayView: UIView!

    lazy var blurEffectView: UIView = {
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return blurEffectView
    }()

    var note: Note? {
        didSet {
            guard let note = note,
                let vc = noteCollectionVC else { return }
            titleLabel.text = note.title
            subTitleLabel.text = note.subTitle
            let tags = note.tags?.count != 0 ? note.tags : ""
            folderLabel.text = tags

            if note.isLocked {
                overlayView.insertSubview(blurEffectView, at: 0)
                overlayTitle.text = note.title
                overlayView.isHidden = false
            } else {
                overlayView.isHidden = true
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

            writeNowButton.isHidden = ((note.content?.count ?? 0) < 500) || vc.isEditing
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        selectedBackgroundView = customSelectedBackgroudView
    }

}
