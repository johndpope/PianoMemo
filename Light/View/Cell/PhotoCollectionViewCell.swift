//
//  PhotoCollectionViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 2018. 8. 21..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var linkImageView: UIImageView!
    @IBOutlet weak var cellButton: UIButton!
    @IBOutlet weak var contentButton: UIButton!
    
    func configure(_ image: UIImage?, isLinked: Bool? = nil) {
        imageView.image = image
        guard let isLinked = isLinked else {return}
        alpha = isLinked ? 0.3 : 1
    }
    
    var cellDidSelected: (() -> ())?
    @IBAction private func action(cell: UIButton) {
        cellDidSelected?()
    }
    
    var contentDidSelected: (() -> ())?
    @IBAction private func action(content: UIButton) {
        contentDidSelected?()
    }
    
}
