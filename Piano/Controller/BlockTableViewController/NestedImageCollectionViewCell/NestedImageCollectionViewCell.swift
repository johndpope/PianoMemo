//
//  NestedImageCollectionViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 31/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit
import Photos

class NestedImageCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    var representedAssetIdentifier: String!
    weak var imageManager: PHCachingImageManager?
    var thumbnailSize: CGSize?

    override func awakeFromNib() {
        super.awakeFromNib()
        let view = View()
        view.backgroundColor = Color.point.withAlphaComponent(0.5)
        selectedBackgroundView = view
        insertSubview(view, aboveSubview: imageView)
    }

    var asset: PHAsset? {
        didSet {
            guard let imageManager = imageManager,
                let thumbnailSize = thumbnailSize,
                let asset = asset else { return }
            representedAssetIdentifier = asset.localIdentifier
            imageManager.requestImage(
                for: asset,
                targetSize: thumbnailSize,
                contentMode: .aspectFill,
                options: nil) {
                [weak self](image, _) in
                guard let self = self else { return }
                // UIKit may have recycled this cell by the handler's activation time.
                // Set the cell's thumbnail image only if it's still showing the same asset.
                if self.representedAssetIdentifier == asset.localIdentifier {
                    self.imageView.image = image
                }
            }
        }
    }

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
