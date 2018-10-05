//
//  MainVC_CollectionViewDataSource.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreGraphics
import CloudKit


extension MainViewController: CollectionViewDataSource {
    func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        
        let note = notes[indexPath.row].note
        let noteViewModel = NoteViewModel(note: note, viewController: self)
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: noteViewModel.note.reuseIdentifier, for: indexPath) as! ViewModelAcceptable & CollectionViewCell
        
        cell.viewModel = noteViewModel
        return cell
    }
    
    func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return notes.count
    }
    
    func numberOfSections(in collectionView: CollectionView) -> Int {
        return 1
    }
}
