//
//  CustomBackgroundTableViewCell.swift
//  Piano
//
//  Created by hoemoon on 22/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

@IBDesignable
class CustomBackgroundTableViewCell: UITableViewCell {
    lazy var customSelectedBackgroudView: UIView = {
        let view = UIView()
        view.backgroundColor = Color(red: 153/255, green: 199/255, blue: 255/255, alpha: 0.3)
        return view
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        selectedBackgroundView = customSelectedBackgroudView
    }
}

