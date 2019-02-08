//
//  ImageSelectionTVCell_delegate.swift
//  Piano
//
//  Created by Kevin Kim on 31/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension ImagePickerTableViewCell: CollectionViewDelegate {
    
    //TODO: selectedIndexPath 갯수에 따라서, attachButton 히든 유무를 결정지어줘야 하고, 갯수가 0으로 변할 때 혹은 0에서 1로 변할 때에 performBatch를 통해 높이를 조절해줘야 한다. 이를 위해서 shouldSelect와 didDeselect에서 체크를 한다.
    
    func collectionView(_ collectionView: CollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        //0 -> 1로 변할 때 attachButton 히든 풀면, 셀 높이가 변하므로 테이블뷰 UI업데이트 시켜줘야함
        if let vc = blockTableViewVC,
            let selectedCount = collectionView.indexPathsForSelectedItems?.count,
            selectedCount == 0 {
            View.performWithoutAnimation {
                vc.tableView.performBatchUpdates({ [weak self] in
                    guard let self = self else { return }
                    self.attachButton.isHidden = false
                    }, completion: nil)
            }
        }
        
        return true
    }
    
    func collectionView(_ collectionView: CollectionView, didDeselectItemAt indexPath: IndexPath) {
        //1 -> 0으로 변할 때 attachButton 히든시키면 셀 높이가 변하므로 테이블뷰 UI업데이트 시켜줘야함
        if let vc = blockTableViewVC,
            let selectedCount = collectionView.indexPathsForSelectedItems?.count,
            selectedCount == 0 {
            View.performWithoutAnimation {
                vc.tableView.performBatchUpdates({ [weak self] in
                    guard let self = self else { return }
                    self.attachButton.isHidden = true
                    }, completion: nil)
            }
            }
    }

    func scrollViewDidScroll(_ scrollView: ScrollView) {
        updateCachedAssets()

    }
}
