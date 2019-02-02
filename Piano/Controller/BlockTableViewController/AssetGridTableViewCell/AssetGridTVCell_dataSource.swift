//
//  ImageSelectionTVCell_dataSource.swift
//  Piano
//
//  Created by Kevin Kim on 31/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension AssetGridTableViewCell: CollectionViewDataSource {
    func numberOfSections(in collectionView: CollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult.count
    }

    func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NestedImageCollectionViewCell.reuseIdentifier, for: indexPath) as? NestedImageCollectionViewCell else { return CollectionViewCell() }
        let asset = fetchResult.object(at: indexPath.item)
        cell.assetGridTableViewCell = self
        cell.asset = asset
        return cell
    }
}

extension AssetGridTableViewCell: CollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: CollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        ()
    }
}
