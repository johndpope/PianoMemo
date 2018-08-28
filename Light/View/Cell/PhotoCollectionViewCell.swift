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
    
    func configure(_ image: UIImage?) {
        imageView.image = image
    }
    
}
