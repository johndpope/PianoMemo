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
    var managedObjectContext: NSManagedObjectContext! {
        return originalNote.managedObjectContext!
    }
    
    
    lazy var noteFetchRequest: NSFetchRequest<Note> = {
        let request:NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedDate", ascending: false)
        request.predicate = NSPredicate(format: "isInTrash == false && SELF != %@", originalNote)
        request.fetchLimit = 100
        request.sortDescriptors = [sort]
        return request
    }()
    lazy var resultsController: NSFetchedResultsController<Note> = {
        let controller = NSFetchedResultsController(
            fetchRequest: noteFetchRequest,
            managedObjectContext: self.managedObjectContext,
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
        
        
        if let titleView = view.createSubviewIfNeeded(PianoTitleView.self) {
            titleView.set(text: "현재 메모에 붙일 메모를 선택하세요. 👆".loc)
            navigationItem.titleView = titleView
        }
        
        
        
        do {
            try resultsController.performFetch()
            collectionView.reloadData()
        } catch {
            print(error.localizedDescription)
        }
        
        showEmptyStateViewIfNeeded()
    }
    
    func showEmptyStateViewIfNeeded(){
        guard self.resultsController.fetchedObjects?.count == 0 else {
            EmptyStateView.detach(on: self.view)
            return
        }
        EmptyStateView.attach(on: self.view, message: "메모가 없어요".loc)
    }
    
    private func noteViewModel(indexPath: IndexPath) -> NoteViewModel {
        let note = resultsController.object(at: indexPath)
        return NoteViewModel(note: note, originNoteForMerge: originalNote, viewController: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let note = selectedNote, note.content?.count == 0 {
            managedObjectContext.performAndWait {
                managedObjectContext.delete(note)
                managedObjectContext.saveIfNeeded()
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
        let noteViewModel = self.noteViewModel(indexPath: indexPath)
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: noteViewModel.note.reuseIdentifier, for: indexPath) as! ViewModelAcceptable & CollectionViewCell
        cell.viewModel = noteViewModel
        return cell
    }
    
    override func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return resultsController.sections?[section].numberOfObjects ?? 0
    }
    
    override func numberOfSections(in collectionView: CollectionView) -> Int {
        return resultsController.sections?.count ?? 0
    }
    
    override func collectionView(_ collectionView: CollectionView, didSelectItemAt indexPath: IndexPath) {
        let note = resultsController.object(at: indexPath)
        selectedNote = note
        performSegue(withIdentifier: "DetailViewController", sender: note)
    }
    
    override func collectionView(_ collectionView: CollectionView, didDeselectItemAt indexPath: IndexPath) {
        resultsController.object(at: indexPath).didDeselectItem(collectionView: collectionView, fromVC: self)
    }
    
//    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        let reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ReusableView", for: indexPath)
//        return reusableView
//    }

}

extension MergeCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.async { [weak self] in
            self?.showEmptyStateViewIfNeeded()
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        func update() {
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
                cell.viewModel = noteViewModel(indexPath: indexPath)
                
            case .move:
                guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
                collectionView.moveItem(at: indexPath, to: newIndexPath)
                
                guard let cell = collectionView.cellForItem(at: newIndexPath) as? NoteCell else { return }
                cell.viewModel = noteViewModel(indexPath: newIndexPath)
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
        return resultsController.object(at: indexPath).size(view: collectionView)
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let firstIndexPathInSection = IndexPath(item: 0, section: section)
        return resultsController.sections?[section].numberOfObjects != 0
            ? resultsController.object(at: firstIndexPathInSection).minimumLineSpacing
            : 0
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
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
