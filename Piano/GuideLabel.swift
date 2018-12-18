//
//  GuideLabel.swift
//  Piano
//
//  Created by hoemoon on 23/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class GuideLabel: UILabel {
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let text = text else { return }
        let attributedString = NSMutableAttributedString(string: text)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5
        paragraphStyle.alignment = .center
        attributedString.addAttributes(
            [.paragraphStyle: paragraphStyle,
             .font: UIFont.systemFont(ofSize: 17) ],
            range: NSRange(location: 0, length: attributedString.length)
        )
        attributedText = attributedString
    }
}

class GuideSubLabel: UILabel {
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let text = text else { return }
        let attributedString = NSMutableAttributedString(string: text)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5
        paragraphStyle.alignment = .center
        attributedString.addAttributes(
            [.paragraphStyle: paragraphStyle,
             .font: UIFont.systemFont(ofSize: 15.8),
             .foregroundColor: UIColor(red: 0.49, green: 0.49, blue: 0.49, alpha: 1.00)],
            range: NSRange(location: 0, length: attributedString.length)
        )
        attributedText = attributedString
    }
}

class HighlightedGuideLabel: UILabel {
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let text = text else { return }
        let attributedString = NSMutableAttributedString(string: text)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 10
        paragraphStyle.alignment = .left
        attributedString.addAttributes(
            [.paragraphStyle: paragraphStyle,
             .font: UIFont.systemFont(ofSize: 15),
             .foregroundColor: UIColor.black],
            range: NSRange(location: 0, length: attributedString.length)
        )
        attributedString.addAttributes(
            [.backgroundColor: UIColor.yellow],
            range: NSRange(location: 0, length: attributedString.length / 2)
        )
        attributedText = attributedString
    }
}
