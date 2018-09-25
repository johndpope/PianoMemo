//
//  PhotoCollectionViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 2018. 8. 21..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import PhotosUI

extension PHAsset: CollectionDatable {
    var sectionImage: Image? { return #imageLiteral(resourceName: "suggestionsPhotos") }
    var sectionTitle: String? { return "Photos".loc }
    var headerSize: CGSize { return CGSize(width: 100, height: 40) }
    var minimumInteritemSpacing: CGFloat { return 2 }
    var minimumLineSpacing: CGFloat { return 2 }
    
    //가로가 크다면 (뷰 가로길이 - (7-1)*마진) / 7
    //세로가 크다면 (뷰 가로길이 - (4-1)*마진) / 4
    func size(view: View) -> CGSize {
        let cellCount: CGFloat = UIScreen.main.bounds.width > UIScreen.main.bounds.height ? 7 : 4
        let safeWidth = view.bounds.width - (view.safeAreaInsets.left + view.safeAreaInsets.right)
        let squareWidth = (safeWidth - CGFloat(cellCount - 1) * (minimumInteritemSpacing)) / cellCount
        return CGSize(width: squareWidth, height: squareWidth)
    }
    
    func didSelectItem(collectionView: CollectionView, fromVC viewController: ViewController) {
        viewController.performSegue(withIdentifier: PhotoDetailViewController.identifier, sender: self)
    }
    
    func sectionInset(view: View) -> EdgeInsets {
        return EdgeInsets(top: 0, left: view.safeAreaInsets.left, bottom: 0, right: view.safeAreaInsets.right)
    }
}



class PHAssetCell: UICollectionViewCell, CollectionDataAcceptable {
    var requestID: PHImageRequestID?
    weak var imageManager: PHCachingImageManager!
    weak var collectionView: CollectionView!
    
    var data: CollectionDatable? {
        didSet {
            guard let asset = self.data as? PHAsset else { return }
            if asset.mediaSubtypes.contains(.photoLive) {
                livePhotoBadgeImageView.image = PHLivePhotoView.livePhotoBadgeImage(options: .overContent)
            }
            
            let scale = UIScreen.main.scale
            let thumbnailSize = CGSize(width: asset.size(view: collectionView).width * scale, height: asset.size(view: collectionView).height * scale)
            requestID = imageManager?.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { [weak self] (image, _) in
                guard let `self` = self, let uImage = image else { return }
                self.imageView.image = uImage
            })
            
        }
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var livePhotoBadgeImageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        livePhotoBadgeImageView.image = nil
        
        if let requestID = self.requestID {
            imageManager.cancelImageRequest(requestID)
        }
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
        view.borderColor = Color.photoSelected
        return view
    }
    
}
