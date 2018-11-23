//
//  GrayScaledImageView.swift
//  Piano
//
//  Created by hoemoon on 23/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class GrayScaledImageView: UIImageView {
    override func awakeFromNib() {
        super.awakeFromNib()
        contentMode = .scaleAspectFit
        if let image = image {
            let template = image.withRenderingMode(.alwaysTemplate)
            tintColor = UIColor(red:0.50, green:0.50, blue:0.50, alpha:1.00)
            self.image = template
        }
    }
}
