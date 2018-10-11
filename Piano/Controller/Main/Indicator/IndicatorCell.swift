//
//  IndicatorCell.swift
//  Light
//
//  Created by hoemoon on 05/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class IndicatorCell: UITableViewCell {
    @IBOutlet weak var attributedLabel: UILabel!
    func configure(_ indicator: Indicator) {
        selectionStyle = .none
        backgroundColor = .clear
        attributedLabel.attributedText = indicator.attrbutedString
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        attributedLabel.attributedText = nil
    }
}
