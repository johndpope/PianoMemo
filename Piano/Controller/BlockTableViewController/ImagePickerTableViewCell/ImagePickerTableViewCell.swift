//
//  ImageSelectionTableViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 31/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit
import Photos

class ImagePickerTableViewCell: UITableViewCell {
    


    weak var blockTableViewVC: BlockTableViewController?
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var segmentControlScrollView: UIScrollView!
    @IBOutlet weak var collectionButton: UIButton!
    @IBOutlet weak var attachButton: UIButton!
    lazy var fetchResult: PHFetchResult<PHAsset> = self.fetchResult(in: nil)
    let userCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)

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
