//
//  PhotoCollectionViewCell.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 10..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import Photos

struct PhotoViewModel: CollectionDatable {
    let asset: PHAsset
    let minimumSize: CGSize
    let imageManager: PHCachingImageManager
    var sectionTitle: String?
    var sectionImage: Image?
    var sectionIdentifier: String?
    
    init(asset: PHAsset, imageManager: PHCachingImageManager, minimumSize: CGSize, sectionTitle: String, sectionImage: Image, sectionIdentifier: String) {
        self.asset = asset
        self.imageManager = imageManager
        self.minimumSize = minimumSize
        self.sectionTitle = sectionTitle
        self.sectionImage = sectionImage
        self.sectionIdentifier = sectionIdentifier
    }
    
    func didSelectItem(fromVC viewController: ViewController) {
        
        viewController.performSegue(withIdentifier: PhotoDetailViewController.identifier, sender: self.asset)
    }
    
    func didDeselectItem(fromVC viewController: ViewController) {
        
    }
    
    func size(maximumWidth: CGFloat) -> CGSize {
        print(maximumWidth)
        return sectionIdentifier != nil
            ? CGSize(width: maximumWidth / 3 - 1, height: maximumWidth / 3 - 1)
            : CGSize(width: maximumWidth / 3 - 1, height: maximumWidth / 3 - 1 + 33)
    }
    
    var headerSize: CGSize = CGSize(width: 100, height: 40)
    var sectionInset: EdgeInsets = EdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    var minimumInteritemSpacing: CGFloat = 1
    var minimumLineSpacing: CGFloat = 1
}

class PhotoViewModelCell: UICollectionViewCell, CollectionDataAcceptable {
    
    var requestID: PHImageRequestID?
    @IBOutlet weak var imageView: UIImageView!
    
    var data: CollectionDatable? {
        didSet {
            guard let viewModel = self.data as? PhotoViewModel else { return }
            
            requestImage(viewModel, size: viewModel.minimumSize) { [weak self] (image, error) in
                if let `self` = self, let image = image {
                    //TODO: 이부분 메인쓰레드로 해야하는지, 그리고 애니메이션으로 스무스하게 달라붙게 만들자.
                    self.imageView.image = image
                }
            }
            
            if let selectedView = selectedBackgroundView {
                insertSubview(selectedView, aboveSubview: imageView)
            }
        }
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        guard let requestID = self.requestID,
            let viewModel = self.data as? PhotoViewModel else { return }
        
        viewModel.imageManager.cancelImageRequest(requestID)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        selectedBackgroundView = borderView
    }
    
}

extension PhotoViewModelCell {
    var borderView: UIView {
        let view = UIView()
        view.backgroundColor = Color.clear
        view.cornerRadius = 15
        view.borderWidth = 2
        view.borderColor = Color(red: 62/255, green: 154/255, blue: 255/255, alpha: 0.8)
        return view
    }
    
    
    private func requestImage(_ model: PhotoViewModel, size: CGSize, completion: @escaping (UIImage?, [AnyHashable : Any]?) -> ()) {
        
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        requestID = model.imageManager.requestImage(for: model.asset, targetSize: size,
                                                    contentMode: .aspectFit, options: options, resultHandler: completion)
    }
}
