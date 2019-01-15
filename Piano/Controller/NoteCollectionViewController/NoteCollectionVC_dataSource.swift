//
//  NoteCollectionVC_dataSource.swift
//  Piano
//
//  Created by Kevin Kim on 04/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension NoteCollectionViewController: CollectionViewDataSource {
    func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NoteCollectionViewCell.reuseIdentifier,
                                                            for: indexPath) as? NoteCollectionViewCell else { return CollectionViewCell() }
        
        let note = resultsController.object(at: indexPath)
        cell.note = note
        cell.noteCollectionVC = self
        cell.moreButton.isHidden = collectionView.isEditable
        return cell
    }
    
    func numberOfSections(in collectionView: CollectionView) -> Int {
        return resultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return resultsController.sections?[section].numberOfObjects ?? 0
    }
}

