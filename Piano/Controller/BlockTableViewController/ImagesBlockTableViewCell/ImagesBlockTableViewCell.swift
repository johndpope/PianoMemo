//
//  ImageBlockTableViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 31/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit
import Photos

class ImagesBlockTableViewCell: UITableViewCell {
    weak var blockTableViewVC: BlockTableViewController?
    @IBOutlet weak var collectionView: UICollectionView!
    let imageManager = PHCachingImageManager()
    var thumbnailSize = CGSize(width: 149 * UIScreen.main.scale, height: 149 * UIScreen.main.scale)
    var previousPreheatRect = CGRect.zero
    var fetchResult: PHFetchResult<PHAsset>!

    // MARK: UIScrollView

}
