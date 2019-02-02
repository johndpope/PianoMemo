//
//  ImageSelectionTVCell_delegate.swift
//  Piano
//
//  Created by Kevin Kim on 31/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension AssetGridTableViewCell: CollectionViewDelegate {
    
    func collectionView(_ collectionView: CollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = fetchResult.object(at: indexPath.item)
//        asset.
    }

    func scrollViewDidScroll(_ scrollView: ScrollView) {
        updateCachedAssets()

    }
}
