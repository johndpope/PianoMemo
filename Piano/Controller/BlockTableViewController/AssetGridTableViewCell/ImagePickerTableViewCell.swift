//
//  ImageSelectionTableViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 31/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit
import Photos

class AssetGridTableViewCell: UITableViewCell {
    
    weak var blockTableViewVC: BlockTableViewController?
    @IBOutlet weak var collectionView: UICollectionView!
    lazy var fetchResult: PHFetchResult<PHAsset> = {
        let allPhotosOptions = PHFetchOptions()
        let date = Date()
        allPhotosOptions.predicate = NSPredicate(format: "creationDate <= %@ && modificationDate <= %@", date as CVarArg, date as CVarArg)
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let photoFetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
        return photoFetchResult
    }()
    
    var thumbnailSize = CGSize(width: 149 * UIScreen.main.scale, height: 149 * UIScreen.main.scale)
    
    var previousPreheatRect = CGRect.zero
    let imageManager = PHCachingImageManager()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        PHPhotoLibrary.shared().register(self)
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    // MARK: Asset Caching
    
    // MARK: UIScrollView
    
    override func prepareForReuse() {
        super.prepareForReuse()
        resetCachedAssets()
    }
    


}


extension AssetGridTableViewCell: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        ()
    }

}
