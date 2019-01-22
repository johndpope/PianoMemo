//
//  PhotoCell.swift
//  Piano
//
//  Created by hoemoon on 22/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    static let id = "PhotoCell"

    @IBOutlet weak var imageView: UIImageView!

    var representedAssetIdentifier: String!

    var thumbnailImage: UIImage! {
        didSet {
            imageView.image = thumbnailImage
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}
