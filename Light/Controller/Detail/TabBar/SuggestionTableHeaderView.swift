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
        rightLabel.text = String(min(count, 99))
        rightLabel.sizeToFit()

        let multiplier: CGFloat = count > 9 ? 1.5 : 2.0
        let size = rightLabel.bounds.size

        rightBackgroundView.translatesAutoresizingMaskIntoConstraints = false

        let constraints: [NSLayoutConstraint] = [
            rightBackgroundView.widthAnchor.constraint(equalToConstant: size.width * multiplier),
            rightBackgroundView.heightAnchor.constraint(equalToConstant: size.width * multiplier),
            rightBackgroundView.centerXAnchor.constraint(equalTo: rightLabel.centerXAnchor),
            rightBackgroundView.centerYAnchor.constraint(equalTo: rightLabel.centerYAnchor)
        ]
        NSLayoutConstraint.activate(constraints)

        rightBackgroundView.cornerRadius  = size.width * multiplier / 2
        rightBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
    }
}
