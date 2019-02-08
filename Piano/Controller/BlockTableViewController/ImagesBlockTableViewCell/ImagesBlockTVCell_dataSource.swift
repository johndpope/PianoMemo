//
//  ImagesBlockTVCell_dataSource.swift
//  Piano
//
//  Created by Kevin Kim on 06/02/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation
import Photos

extension ImagesBlockTableViewCell: CollectionViewDataSource {
    func numberOfSections(in collectionView: CollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult.count
    }
    
    func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NestedImageCollectionViewCell.reuseIdentifier, for: indexPath) as? NestedImageCollectionViewCell else { return CollectionViewCell() }
        
        let asset = fetchResult.object(at: indexPath.item)
        cell.imageManager = imageManager
        cell.thumbnailSize = thumbnailSize
        cell.asset = asset
        return cell
    }
}

extension ImagesBlockTableViewCell: CollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: CollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        ()
    }
}
