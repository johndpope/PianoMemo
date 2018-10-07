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
        let note = syncController.resultsController.object(at: indexPath)
        selectedNote = note
        note.didSelectItem(collectionView: collectionView, fromVC: self)
    }
    
    func collectionView(_ collectionView: CollectionView, didDeselectItemAt indexPath: IndexPath) {
        syncController.resultsController.object(at: indexPath).didDeselectItem(collectionView: collectionView, fromVC: self)
    }
}

extension MainViewController: CollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, insetForSectionAt section: Int) -> EdgeInsets {
        return syncController.resultsController.fetchedObjects?.first?.sectionInset(view: collectionView) ?? EdgeInsets(top: 0, left: 8, bottom: bottomView.bounds.height, right: 8)
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let note = notes[indexPath.row].note
        return note.size(view: collectionView)
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let firstIndexPathInSection = IndexPath(item: 0, section: section)
        guard let count = syncController.resultsController.sections?[section].numberOfObjects, count != 0 else { return 0 }
        let note = syncController.resultsController.object(at: firstIndexPathInSection)
        return note.minimumLineSpacing
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let firstIndexPathInSection = IndexPath(item: 0, section: section)
        guard let count = syncController.resultsController.sections?[section].numberOfObjects, count != 0 else { return 0 }
        let note = syncController.resultsController.object(at: firstIndexPathInSection)
        return note.minimumInteritemSpacing
    }
    
}
