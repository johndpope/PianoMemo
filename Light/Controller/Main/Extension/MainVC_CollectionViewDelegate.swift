//
//  MainVC_CollectionViewDelegate.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreGraphics

extension MainViewController {
    func collectionView(_ collectionView: CollectionView, didSelectItemAt indexPath: IndexPath) {
        syncController.resultsController.object(at: indexPath).didSelectItem(collectionView: collectionView, fromVC: self)
    }
    
    func collectionView(_ collectionView: CollectionView, didDeselectItemAt indexPath: IndexPath) {
        syncController.resultsController.object(at: indexPath).didDeselectItem(collectionView: collectionView, fromVC: self)
    }
}

extension MainViewController: CollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, insetForSectionAt section: Int) -> EdgeInsets {
        let firstIndexPathInSection = IndexPath(item: 0, section: section)
        return syncController.resultsController.sections?[section].numberOfObjects != 0
            ? syncController.resultsController.object(at: firstIndexPathInSection).sectionInset(view: collectionView)
            : EdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return syncController.resultsController.object(at: indexPath).size(view: collectionView)
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let firstIndexPathInSection = IndexPath(item: 0, section: section)
        return syncController.resultsController.sections?[section].numberOfObjects != 0
            ? syncController.resultsController.object(at: firstIndexPathInSection).minimumLineSpacing
            : 0
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let firstIndexPathInSection = IndexPath(item: 0, section: section)
        return syncController.resultsController.sections?[section].numberOfObjects != 0
            ? syncController.resultsController.object(at: firstIndexPathInSection).minimumInteritemSpacing
            : 0
    }
    
}
