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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NoteCollectionViewCell.reuseIdentifier, for: indexPath) as! NoteCollectionViewCell
        configure(noteCell: cell, indexPath: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return resultsController.sections?[section].numberOfObjects ?? 0
    }
    
    private func configure(noteCell: NoteCollectionViewCell, indexPath: IndexPath) {
        let note = resultsController.object(at: indexPath)
        
        
        if let date = note.modifiedDate {
            noteCell.dateLabel.text = DateFormatter.sharedInstance.string(from: date)
            if Calendar.current.isDateInToday(date) {
                noteCell.dateLabel.textColor = Color.point
            } else {
                noteCell.dateLabel.textColor = Color.lightGray
            }
        }
        
        
        guard let content = note.content else { return }
        
        var strArray = content.split(separator: "\n").compactMap { return $0.count != 0 ? $0 : nil }
        
        guard strArray.count != 0 else {
            noteCell.titleLabel.text = "No Title".loc
            noteCell.contentLabel.text = "No Body".loc
            return
        }
        
        let firstStr = String(strArray.removeFirst())
        let firstLabelLimit = 50
        noteCell.titleLabel.text = firstStr.count < firstLabelLimit ? firstStr : firstStr.substring(with: NSMakeRange(0, firstLabelLimit))
        
        
        guard strArray.count != 0 else {
            noteCell.contentLabel.text = "No Body".loc
            return
        }

        let secondLabelLimit = 100
        var secondStr = ""
        while strArray.count != 0,  secondStr.count < secondLabelLimit {
            secondStr += (String(strArray.removeFirst()) + " ")
        }
        
        noteCell.contentLabel.text = secondStr

    }
}
