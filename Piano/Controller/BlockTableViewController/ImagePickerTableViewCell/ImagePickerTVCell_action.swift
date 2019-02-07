//
//  ImageSelectionTVCell_action.swift
//  Piano
//
//  Created by Kevin Kim on 31/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation
import Photos


fileprivate enum CollectionViewType: Int {
    case all = 0
    case collection
}

fileprivate extension CollectionView {
    var type: CollectionViewType {
        get {
            return CollectionViewType(rawValue: tag)!
        } set {
            tag = newValue.rawValue
        }
    }

}

extension ImagePickerTableViewCell {
    
    @IBAction func valueChanged(_ sender: SegmentControl) {
        guard let assetCollection = userCollections.object(at: sender.selectedSegmentIndex) as? PHAssetCollection,
            let vc = blockTableViewVC else { return }
    
        View.performWithoutAnimation { [weak self] in
            guard let self = self else { return }
            vc.tableView.performBatchUpdates({
                self.fetchResult = fetchResult(in: assetCollection)
                self.collectionView.contentOffset = CGPoint.zero
                self.collectionView.reloadData()
                segmentControlScrollView.isHidden = true
                self.collectionButton.setTitle(assetCollection.localizedTitle, for: .normal)
                self.collectionButton.isHidden = false
                self.collectionView.type = CollectionViewType.collection
            }, completion: nil)
            
        }
        
        
    }
    
    @IBAction func tapAttach(_ sender: Button) {
        
    }
    
    @IBAction func touchUpInsideCollectionBtn(_ sender: Button) {
        guard let vc = blockTableViewVC else { return }
        View.performWithoutAnimation {
            vc.tableView.performBatchUpdates({ [weak self] in
                guard let self = self else { return }
                switch collectionView.type {
                case .all:
                    sender.isHidden = true
                    self.setSegmentControl()
                    self.segmentControlScrollView.isHidden = false
                    self.collectionView.type = .collection
                    
                case .collection:
                    sender.setTitle("All Photos".loc, for: .normal)
                    fetchResult = fetchResult(in: nil)
                    self.collectionView.contentOffset = CGPoint.zero
                    collectionView.reloadData()
                    collectionView.type = .all
                }
                
            }, completion: nil)
        }
    }
}
