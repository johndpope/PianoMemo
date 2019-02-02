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
    weak var assetGridTableViewCell: AssetGridTableViewCell?
    
    var asset: PHAsset! {
        didSet {
            guard let gridTVCell = assetGridTableViewCell else { return }
            representedAssetIdentifier = asset.localIdentifier
            gridTVCell.imageManager.requestImage(for: asset, targetSize: gridTVCell.thumbnailSize, contentMode: .aspectFill, options: nil) { [weak self](image, _) in
                guard let self = self else { return }
                // UIKit may have recycled this cell by the handler's activation time.
                // Set the cell's thumbnail image only if it's still showing the same asset.
                if self.representedAssetIdentifier == self.asset.localIdentifier {
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
