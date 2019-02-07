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
    
        View.performWithoutAnimation {
            vc.tableView.performBatchUpdates({
                fetchResult = fetchResult(in: assetCollection)
                collectionButton.setTitle(assetCollection.localizedTitle, for: .normal)
                collectionButton.isHidden = false
                segmentControlScrollView.isHidden = true
                attachButton.isHidden = true
                
                collectionView.contentOffset = CGPoint.zero
                resetCachedAssets()
                collectionView.reloadData()
                collectionView.type = CollectionViewType.collection
            }, completion: nil)
            
        }
        
        
    }
    
    @IBAction func tapAttach(_ sender: Button) {
        guard let vc = blockTableViewVC,
            let indexPathsForSelectedItems = collectionView.indexPathsForSelectedItems,
            let indexPath = vc.tableView.indexPath(for: self) else { return }
        //모든 값을 초기 상태로 만들기
        reset()
        
        let identifiers = indexPathsForSelectedItems.map {
            return fetchResult.object(at: $0.item).localIdentifier
        }
        let pianoKey = PianoAssetKey.createString(localIdentifiers: identifiers)
        //TODO: 여기서 이미지를 코어데이터에 저장해야 한다.
        vc.dataSource[indexPath.section][indexPath.row] = pianoKey
        View.performWithoutAnimation {
            vc.tableView.performBatchUpdates({
                vc.tableView.reloadRows(at: [indexPath], with: .none)
            }, completion: nil)
        }
        
    }
    
    @IBAction func touchUpInsideCollectionBtn(_ sender: Button) {
        guard let vc = blockTableViewVC else { return }
        View.performWithoutAnimation {
            vc.tableView.performBatchUpdates({
                switch collectionView.type {
                case .all:
                    collectionButton.isHidden = true
                    segmentControlScrollView.isHidden = false
                    collectionView.type = .collection
                    
                case .collection:
                    collectionButton.setTitle("All Photos".loc, for: .normal)
                    fetchResult = fetchResult(in: nil)
                    attachButton.isHidden = true
                    
                    collectionView.contentOffset = CGPoint.zero
                    resetCachedAssets()
                    collectionView.reloadData()
                    collectionView.type = .all
                }
                
            }, completion: nil)
        }
    }
}

extension ImagePickerTableViewCell {
    internal func reset() {
        guard let vc = blockTableViewVC else { return }
        View.performWithoutAnimation {
            vc.tableView.performBatchUpdates({
                attachButton.isHidden = true
                collectionButton.setTitle("All Photos".loc, for: .normal)
                collectionButton.isHidden = false
                segmentControlScrollView.isHidden = true
                
                fetchResult = fetchResult(in: nil)
                collectionView.contentOffset = CGPoint.zero
                resetCachedAssets()
                collectionView.reloadData()
                collectionView.type = CollectionViewType.all
            }, completion: nil)
        }
        
    }
}
