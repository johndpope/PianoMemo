//
//  SuggestionTableHeaderView.swift
//  Light
//
//  Created by hoemoon on 31/08/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class SuggestionTableHeaderView: UIView {
    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var rightLabel: UILabel!
    @IBOutlet weak var rightBackgroundView: UIView!

    func configure(title: String, count: Int) {
        leftLabel.text = title
        rightLabel.text = String(max(count, 99))
        rightLabel.sizeToFit()

        let size = rightLabel.bounds.size

        rightBackgroundView.translatesAutoresizingMaskIntoConstraints = false

        let constraints: [NSLayoutConstraint] = [
            rightBackgroundView.widthAnchor.constraint(equalToConstant: size.width * 2),
            rightBackgroundView.heightAnchor.constraint(equalToConstant: size.width * 2),
            rightBackgroundView.centerXAnchor.constraint(equalTo: rightLabel.centerXAnchor),
            rightBackgroundView.centerYAnchor.constraint(equalTo: rightLabel.centerYAnchor)
        ]
        NSLayoutConstraint.activate(constraints)

        rightBackgroundView.cornerRadius  = size.width
        rightBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
    }
}
