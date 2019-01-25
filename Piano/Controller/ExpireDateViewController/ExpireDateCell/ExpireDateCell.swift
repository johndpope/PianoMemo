//
//  ExpireDateCell.swift
//  Piano
//
//  Created by Kevin Kim on 23/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class ExpireDateCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!

    var data: ExpireDateViewController.ExpireTime {
        get {
            let name = titleLabel.text ?? ""
            let date = DateFormatter.sharedInstance.date(from: subTitleLabel.text ?? "") ?? Date()
            return ExpireDateViewController.ExpireTime(name: name, date: date)

        } set {
            titleLabel.text = newValue.name
            subTitleLabel.text = DateFormatter.sharedInstance.string(from: newValue.date)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        selectedBackgroundView = customSelectedBackgroudView
    }

}
