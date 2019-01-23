//
//  PhotoProvider.swift
//  Piano
//
//  Created by hoemoon on 22/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit
import Photos

class ImageInputDataService: NSObject {
    private var photoFetchResult: PHFetchResult<PHAsset>!
    private var thumbnailSize: CGSize!
    private var collectionView: UICollectionView!
    lazy var cacheManager = PHCachingImageManager()

    func setup(with collectionView: UICollectionView) {
        self.collectionView = collectionView
    }

}
