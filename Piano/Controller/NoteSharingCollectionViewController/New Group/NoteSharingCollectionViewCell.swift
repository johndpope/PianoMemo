//
//  NoteSharingCollectionViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 24/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class NoteSharingCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!

    var data: NoteSharingCollectionViewController.NoteSharingType? {
        get {
            return nil
        } set {
            guard let type = newValue else { return }
            switch type {
            case .clipboard:
                titleLabel.text = "Copy All".loc
                subTitleLabel.text = "Copy the entire contents to the clipboard.".loc

            case .image:
                titleLabel.text = "Export to image".loc
                subTitleLabel.text = "Export the entire contents to image.".loc

            case .pdf:
                titleLabel.text = "Export to pdf".loc
                subTitleLabel.text = "Export the entire contents to pdf.".loc
            }
        }
    }
}
