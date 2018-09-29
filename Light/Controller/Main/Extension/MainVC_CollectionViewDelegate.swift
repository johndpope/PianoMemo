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
        let note = resultsController.object(at: indexPath)
        note.didSelectItem(collectionView: collectionView, fromVC: self)
    }
    
    func collectionView(_ collectionView: CollectionView, didDeselectItemAt indexPath: IndexPath) {
        let note = resultsController.object(at: indexPath)
        note.didDeselectItem(collectionView: collectionView, fromVC: self)
    }
}

extension MainViewController: CollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, insetForSectionAt section: Int) -> EdgeInsets {
        return EdgeInsets(top: 0, left: 0, bottom: bottomView.bounds.height, right: 0)
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let note = resultsController.object(at: indexPath)
        return note.size(view: collectionView)
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let firstIndexPathInSection = IndexPath(item: 0, section: section)
        guard resultsController.sections?[section].numberOfObjects != 0 else { return 0 }
        let note = resultsController.object(at: firstIndexPathInSection)
        return note.minimumLineSpacing
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let firstIndexPathInSection = IndexPath(item: 0, section: section)
        guard resultsController.sections?[section].numberOfObjects != 0 else { return 0 }
        let note = resultsController.object(at: firstIndexPathInSection)
        return note.minimumInteritemSpacing
    }
    
}
