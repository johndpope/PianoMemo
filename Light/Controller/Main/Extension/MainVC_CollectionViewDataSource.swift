//
//  MainVC_CollectionViewDataSource.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreGraphics

extension MainViewController: CollectionViewDataSource {
    
    func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NoteCollectionViewCell", for: indexPath) as! NoteCollectionViewCell
        configure(noteCell: cell, indexPath: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return resultsController.sections?[section].numberOfObjects ?? 0
    }
    
    private func configure(noteCell: NoteCollectionViewCell, indexPath: IndexPath) {
        let note = resultsController.object(at: indexPath)
        
        if let count = note.content?.count, count > 30 {
            let range = NSMakeRange(0, 30)
            noteCell.contentLabel.text = note.content?.substring(with: range)
        } else {
            noteCell.contentLabel.text = note.content
        }
        
        if let date = note.modifiedDate {
            noteCell.dateLabel.text = DateFormatter.sharedInstance.string(from: date)
            if Calendar.current.isDateInToday(date) {
                noteCell.dateLabel.textColor = Color.point
            } else {
                noteCell.dateLabel.textColor = Color.lightGray
            }
        }
    }
}
