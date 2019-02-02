//
//  ImageSelectionTableViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 31/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit
import Photos

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        guard let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect) else { return [] }
        return allLayoutAttributes.map { $0.indexPath }
    }
}

class ImagePickerTableViewCell: UITableViewCell {

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
    var thumbnailSize: CGSize!
    var previousPreheatRect = CGRect.zero
    lazy var cacheManager = PHCachingImageManager()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        PHPhotoLibrary.shared().register(self)
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

}

extension ImagePickerTableViewCell: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        ()
    }

}
