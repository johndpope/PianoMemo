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

    lazy var separator: UIView = {
        let view = UIView()
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.lightGray.cgColor
        return view
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        selectedBackgroundView = customSelectedBackgroudView
        contentView.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false

        let contstraints = [
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5)
        ]
        NSLayoutConstraint.activate(contstraints)
    }
}

