////
////  SuggestionTableHeaderView.swift
////  Light
////
////  Created by hoemoon on 31/08/2018.
////  Copyright © 2018 Piano. All rights reserved.
////
//
//import UIKit
//
//class SuggestionTableHeaderView: UIView {
//    @IBOutlet weak var leftLabel: UILabel!
//    @IBOutlet weak var rightLabel: UILabel!
//    @IBOutlet weak var rightBackgroundView: UIView!
//
//    private var rightBackgroundWidthConstraint: NSLayoutConstraint!
//    private var rightBackgroundHeightConstraint: NSLayoutConstraint!
//
//    func configure(title: String, count: Int) {
//        rightLabel.text = String(min(count, 99))
//        rightLabel.sizeToFit()
//
//        let multiplier: CGFloat = count > 9 ? 1.7 : 1.9
//        let size = rightLabel.bounds.size
//
//        if rightBackgroundView.constraints.count == 0 {
//            rightBackgroundView.translatesAutoresizingMaskIntoConstraints = false
//
//            rightBackgroundWidthConstraint = rightBackgroundView.widthAnchor.constraint(equalToConstant: size.width * multiplier)
//            rightBackgroundHeightConstraint = rightBackgroundView.heightAnchor.constraint(equalToConstant: size.width * multiplier)
//
//            let constraints: [NSLayoutConstraint] = [
//                rightBackgroundWidthConstraint,
//                rightBackgroundHeightConstraint,
//                rightBackgroundView.centerXAnchor.constraint(equalTo: rightLabel.centerXAnchor),
//                rightBackgroundView.centerYAnchor.constraint(equalTo: rightLabel.centerYAnchor)
//            ]
//            NSLayoutConstraint.activate(constraints)
//
//            leftLabel.text = title
//            rightBackgroundView.cornerRadius  = size.width * multiplier / 2
//            rightBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
//        }
//
//        rightBackgroundWidthConstraint.constant = size.width * multiplier
//        rightBackgroundHeightConstraint.constant = size.width * multiplier
//
//    }
//}
