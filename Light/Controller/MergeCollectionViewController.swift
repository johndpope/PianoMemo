//
//  MergeCollectionViewController.swift
//  Piano
//
//  Created by Kevin Kim on 29/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import CoreData

class MergeManager {
    var keywordCache: [NSManagedObjectID : [String]] = [:]
}

//다른 디바이스에서 혹은 공유된 곳에서 지워지면 컨텍스트가 nil이 될 것임
class MergeCollectionViewController: UICollectionViewController, CollectionRegisterable {
    var mergeManager = MergeManager()
    var selectedNote: Note?
    
    var originalNote: Note!
    var managedObjectContext: NSManagedObjectContext? {
        return originalNote.managedObjectContext
    }
    
    
    lazy var noteFetchRequest: NSFetchRequest<Note> = {
        let request:NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedDate", ascending: false)
        request.predicate = NSPredicate(format: "isInTrash == false && SELF != %@", originalNote)
        request.fetchLimit = 100
        request.sortDescriptors = [sort]
        return request
    }()
    lazy var resultsController: NSFetchedResultsController<Note>? = {
        guard let backgroundContext = self.managedObjectContext else { return nil }
        let controller = NSFetchedResultsController(
            fetchRequest: noteFetchRequest,
            managedObjectContext: backgroundContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        return controller
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerCell(NoteCell.self)
        clearsSelectionOnViewWillAppear = true
        
        do {
            try resultsController?.performFetch()
            collectionView.reloadData()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let note = selectedNote, note.content?.count == 0 {
            managedObjectContext?.performAndWait {
                managedObjectContext?.delete(note)
                managedObjectContext?.saveIfNeeded()
            }
        }
        selectedNote = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? DetailViewController,
            let note = sender as? Note {
            des.note = note
            des.state = .merge
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        guard let resultsController = resultsController else { return CollectionViewCell() }
        let note = resultsController.object(at: indexPath)
        let viewModel = NoteViewModel(note: note, originNoteForMerge: originalNote)
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: note.reuseIdentifier, for: indexPath) as! ViewModelAcceptable & CollectionViewCell
        cell.viewModel = viewModel
        return cell
    }
    
    override func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return resultsController?.sections?[section].numberOfObjects ?? 0
    }
    
    override func numberOfSections(in collectionView: CollectionView) -> Int {
        return resultsController?.sections?.count ?? 0
    }
    
    override func collectionView(_ collectionView: CollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let note = resultsController?.object(at: indexPath) else { return }
        selectedNote = note
        performSegue(withIdentifier: "DetailViewController", sender: note)
    }
    
    override func collectionView(_ collectionView: CollectionView, didDeselectItemAt indexPath: IndexPath) {
        resultsController?.object(at: indexPath).didDeselectItem(collectionView: collectionView, fromVC: self)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ReusableView", for: indexPath)
        return reusableView
    }

}

extension MergeCollectionViewController: NSFetchedResultsControllerDelegate {
    
//    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        if let share = cloudManager?.share.targetShare {
//            DispatchQueue.main.sync {
//                guard let sharedNote = self.resultsController.fetchedObjects?.first(where: {
//                    $0.record()?.share?.recordID == share.recordID}) else {return}
//                self.performSegue(withIdentifier: DetailViewController.identifier, sender: sharedNote)
//                cloudManager?.share.targetShare = nil
//                self.bottomView.textView.resignFirstResponder()
//            }
//        }
//    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        func update() {
            guard let resultsController = resultsController else { return }
            switch type {
            case .insert:
                guard let newIndexPath = newIndexPath else {return}
                collectionView.insertItems(at: [newIndexPath])
            case .delete:
                guard let indexPath = indexPath else {return}
                collectionView.deleteItems(at: [indexPath])
            case .update:
                guard let indexPath = indexPath,
                    let cell = collectionView.cellForItem(at: indexPath) as? NoteCell else {return}
                let note = resultsController.object(at: indexPath)
                let viewModel = NoteViewModel(note: note, originNoteForMerge: originalNote)
                cell.viewModel = viewModel
                
            case .move:
                guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
                collectionView.moveItem(at: indexPath, to: newIndexPath)
                
                guard let cell = collectionView.cellForItem(at: newIndexPath) as? NoteCell else { return }
                let note = resultsController.object(at: newIndexPath)
                let viewModel = NoteViewModel(note: note, originNoteForMerge: originalNote)
                cell.viewModel = viewModel
                
            }
            
            //            if let newNote = anObject as? Note,
            //                let noteEditable = noteEditable,
            //                let editingNote = noteEditable.note,
            //                newNote == editingNote {
            //
            //                noteEditable.note = newNote
            //            }
        }
        
        if !Thread.isMainThread {
            DispatchQueue.main.sync {
                update()
            }
        } else {
            update()
        }
    }
}

extension MergeCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: 100, height: 30)
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, insetForSectionAt section: Int) -> EdgeInsets {
        return EdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return resultsController?.object(at: indexPath).size(view: collectionView) ?? CGSize.zero
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        guard let resultsController = resultsController else { return 0 }
        let firstIndexPathInSection = IndexPath(item: 0, section: section)
        return resultsController.sections?[section].numberOfObjects != 0
            ? resultsController.object(at: firstIndexPathInSection).minimumLineSpacing
            : 0
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        guard let resultsController = resultsController else { return 0 }
        let firstIndexPathInSection = IndexPath(item: 0, section: section)
        return resultsController.sections?[section].numberOfObjects != 0
            ? resultsController.object(at: firstIndexPathInSection).minimumInteritemSpacing
            : 0
    }
}

extension MergeCollectionViewController {
    // 현재 컬렉션뷰의 셀 갯수가 (fetchLimit / 0.9) 보다 큰 경우,
    // 맨 밑까지 스크롤하면 fetchLimit을 증가시킵니다.
    override func scrollViewDidScroll(_ scrollView: ScrollView) {
        guard let resultsController = resultsController else { return }
        if scrollView.contentOffset.y > 0,
            scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height) {
            
            if collectionView.numberOfItems(inSection: 0) > 90 {
                noteFetchRequest.fetchLimit += 50
                try? resultsController.performFetch()
                collectionView.reloadData()
            }
        }
    }
}
