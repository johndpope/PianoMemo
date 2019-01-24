//
//  NoteCollectionVC_resultsControllerDelegate.swift
//  Piano
//
//  Created by Kevin Kim on 04/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation
import CoreData

extension NoteCollectionViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let collectionView = collectionView else {
            print("resultsControllerDelegate 값 변경하려는 데 컬렉션 뷰 nil되었다")
            return
        }
        
        collectionView.performBatchUpdates({
            switch type {
            case .delete:
                guard let indexPath = indexPath else { return }
                collectionView.deleteItems(at: [indexPath])

            case .insert:
                guard let newIndexPath = newIndexPath else { return }
                collectionView.insertItems(at: [newIndexPath])

            case .update:
                guard let indexPath = indexPath,
                    let note = controller.object(at: indexPath) as? Note,
                    let cell = collectionView.cellForItem(at: indexPath) as? NoteCollectionViewCell else { return }
                cell.note = note
                
            case .move:
                guard let indexPath = indexPath,
                    let newIndexPath = newIndexPath else { return }
                collectionView.moveItem(at: indexPath, to: newIndexPath)

            }
        }, completion: nil)

    }
}
