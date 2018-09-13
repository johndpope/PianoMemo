//
//  PhotoCollectionViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 2018. 8. 21..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import Photos

class PhotoPickerCollectionViewCell: UICollectionViewCell {
    
    var representedAssetIdentifier: String!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var livePhotoBadgeImageView: UIImageView!
    
    var thumbnailImage: UIImage! {
        didSet {
            imageView.image = thumbnailImage
        }
    }
    
    var livePhotoBadgeImage: UIImage! {
        didSet {
            livePhotoBadgeImageView.image = livePhotoBadgeImage
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImage = nil
        livePhotoBadgeImageView.image = nil
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if let selectedView = selectedBackgroundView {
            insertSubview(selectedView, aboveSubview: imageView)
        }
    }

    

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        selectedBackgroundView = borderView
    }
    
    var borderView: UIView {
        let view = UIView()
        view.backgroundColor = Color.clear
        view.borderWidth = 4
        view.borderColor = Color.point
        return view
    }
    
}
