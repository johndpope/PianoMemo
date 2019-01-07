//
//  NoteCollectionView_delegate.swift
//  Piano
//
//  Created by Kevin Kim on 04/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension NoteCollectionViewController: CollectionViewDelegate {
    func collectionView(_ collectionView: CollectionView, didSelectItemAt indexPath: IndexPath) {
        setToolbarBtnsEnabled()
    }
    
    func collectionView(_ collectionView: CollectionView, didDeselectItemAt indexPath: IndexPath) {
        setToolbarBtnsEnabled()
    }
}
