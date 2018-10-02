//
//  TrashCollectionViewController.swift
//  Piano
//
//  Created by Kevin Kim on 01/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import CoreData

class TrashCollectionViewController: UICollectionViewController, CollectionRegisterable {

    var selectedNote: Note?
    var backgroundContext: NSManagedObjectContext!
    
    lazy var noteFetchRequest: NSFetchRequest<Note> = {
        let request:NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedDate", ascending: false)
        request.predicate = NSPredicate(format: "isInTrash == true")
        request.sortDescriptors = [sort]
        return request
    }()
    
    lazy var resultsController: NSFetchedResultsController<Note> = {
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
        clearsSelectionOnViewWillAppear = true
        registerCell(NoteCell.self)
        do {
            try resultsController.performFetch()
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
        EmptyStateView.attach(on: self.view, message: "휴지통이 비어있어요".loc)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerAllNotification()
        
        navigationController?.setToolbarHidden(false, animated: true)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        collectionView.indexPathsForSelectedItems?.forEach {
            collectionView.deselectItem(at: $0, animated: true)
        }
        
        if let note = selectedNote, note.content?.count == 0 {
            backgroundContext.performAndWait {
                backgroundContext.delete(note)
                backgroundContext.saveIfNeeded()
            }
        }
        selectedNote = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unRegisterAllNotification()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? DetailViewController,
            let note = sender as? Note {
            des.note = note
            des.state = .trash
            return
        }
    }
    
    internal func noteViewModel(indexPath: IndexPath) -> NoteViewModel {
        let note = resultsController.object(at: indexPath)
        return NoteViewModel(note: note, originNoteForMerge: nil, viewController: self)
    }
    

    @IBAction func restoreAll(_ sender: Any) {
        Alert.restoreAll(from: self) { [weak self] in
            guard let self = self else { return }
            
            self.resultsController.fetchedObjects?.forEach { note in
                self.backgroundContext.perform {
                    note.modifiedDate = Date()
                    note.isInTrash = false
                    self.backgroundContext.saveIfNeeded()
                }
            }
            
            //이슈: 한꺼번에 지우려고 하니까 컬렉션뷰에서 에러남, 관련 링크: https://stackoverflow.com/questions/47614583/delete-multiple-core-data-objects-issue-with-nsfetchedresultscontroller
//            let request = NSBatchUpdateRequest(entityName: "Note")
//            request.resultType = .updatedObjectIDsResultType
//            let predicate = NSPredicate(format: "isInTrash == true")
//            request.predicate = predicate
//            request.propertiesToUpdate = ["isInTrash" : false, "modifiedDate" : Date()]
//
//            do {
//                let result = try self.backgroundContext.execute(request) as? NSBatchUpdateResult
//                let objectIDArray = result?.result as? [NSManagedObjectID]
//                let changes = [NSUpdatedObjectsKey : objectIDArray]
//
//                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes as [AnyHashable : Any], into: [self.backgroundContext])
//
//                self.dismiss(animated: true, completion: nil)
//            } catch {
//                print(error.localizedDescription)
//            }
        }
    }
    
    @IBAction func deleteAll(_ sender: Any) {
        Alert.deleteAll(from: self) { [weak self] in
            guard let self = self else { return }
            
            self.resultsController.fetchedObjects?.forEach { note in
                self.backgroundContext.perform {
                    self.backgroundContext.delete(note)
                    self.backgroundContext.saveIfNeeded()
                }
            }
            
//            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
//            fetch.predicate = NSPredicate(format: "isInTrash == true")
//            let request = NSBatchDeleteRequest(fetchRequest: fetch)
//            request.resultType = .resultTypeObjectIDs
//            do {
//                let result = try self.backgroundContext.execute(request) as? NSBatchDeleteResult
//                let objectIDArray = result?.result as? [NSManagedObjectID]
//                let changes = [NSDeletedObjectsKey : objectIDArray]
//                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes as [AnyHashable : Any], into: [self.backgroundContext])
//                (self.navigationController as? TransParentNavigationController)?.show(message: "완전히 삭제되었습니다", color: Color.red)
//            } catch {
//                print(error.localizedDescription)
//            }
            
        }
    }
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    internal func registerAllNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeStatusBarOrientation(_:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    internal func unRegisterAllNotification(){
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func didChangeStatusBarOrientation(_ notification: Notification) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    // 현재 컬렉션뷰의 셀 갯수가 (fetchLimit / 0.9) 보다 큰 경우,
    // 맨 밑까지 스크롤하면 fetchLimit을 증가시킵니다.
    override func scrollViewDidScroll(_ scrollView: ScrollView) {
//        super.scrollViewDidScroll(scrollView)
        
        if scrollView.contentOffset.y > 0,
            scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height) {
            
            if collectionView.numberOfItems(inSection: 0) > 90 {
                noteFetchRequest.fetchLimit += 50
                try? resultsController.performFetch()
                collectionView.reloadData()
            }
        }
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
        note.didSelectItem(collectionView: collectionView, fromVC: self)
    }
    
    override func collectionView(_ collectionView: CollectionView, didDeselectItemAt indexPath: IndexPath) {
        let note = resultsController.object(at: indexPath)
        note.didDeselectItem(collectionView: collectionView, fromVC: self)
    }
    
}

extension TrashCollectionViewController: CollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, insetForSectionAt section: Int) -> EdgeInsets {
        return resultsController.fetchedObjects?.first?.sectionInset(view: collectionView) ?? EdgeInsets(top: 0, left: 8, bottom: toolHeight, right: 8)
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let note = resultsController.object(at: indexPath)
        return note.size(view: collectionView)
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let firstIndexPathInSection = IndexPath(item: 0, section: section)
        guard let count = resultsController.sections?[section].numberOfObjects, count != 0 else { return 0 }
        let note = resultsController.object(at: firstIndexPathInSection)
        return note.minimumLineSpacing
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let firstIndexPathInSection = IndexPath(item: 0, section: section)
        guard let count = resultsController.sections?[section].numberOfObjects, count != 0 else { return 0 }
        let note = resultsController.object(at: firstIndexPathInSection)
        return note.minimumInteritemSpacing
    }
}


extension TrashCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let share = cloudManager?.share.targetShare {
            DispatchQueue.main.sync {
                guard let sharedNote = self.resultsController.fetchedObjects?.first(where: {
                    $0.record()?.share?.recordID == share.recordID}) else {return}
                self.performSegue(withIdentifier: DetailViewController.identifier, sender: sharedNote)
                cloudManager?.share.targetShare = nil
            }
        }
        
        //Note: 이 스코프 안에서는 항상 비동기로 해줘야함.
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
                cell.viewModel = self.noteViewModel(indexPath: indexPath)
                
            case .move:
                guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
                collectionView.moveItem(at: indexPath, to: newIndexPath)
                
                guard let cell = collectionView.cellForItem(at: newIndexPath) as? NoteCell else { return }
                cell.viewModel = self.noteViewModel(indexPath: newIndexPath)
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
