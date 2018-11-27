//
//  TempletedImage.swift
//  Piano
//
//  Created by hoemoon on 26/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

@IBDesignable class TempletedImageView: UIImageView {
    override func awakeFromNib() {
        super.awakeFromNib()
        contentMode = .scaleAspectFit
        if let image = image {
            let template = image.withRenderingMode(.alwaysTemplate)
            self.image = template
        }
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        contentMode = .scaleAspectFit
        if let image = image {
            let template = image.withRenderingMode(.alwaysTemplate)
            self.image = template
        }
    }
}
