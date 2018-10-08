//
//  TrashCollectionViewController.swift
//  Piano
//
//  Created by Kevin Kim on 01/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import CoreData
import DifferenceKit

class TrashCollectionViewController: UICollectionViewController, CollectionRegisterable, SyncControllable {

    var selectedNote: Note?
    weak var syncController: Synchronizable!
    internal var notes = [NoteWrapper]()

    override func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = true
        registerCell(NoteCell.self)
        syncController.setTrashUIRefreshDelegate(self) { [weak self] in
            self?.showEmptyStateViewIfNeeded()
        }
    }
    
    func showEmptyStateViewIfNeeded(){
        guard notes.count == 0 else {
            EmptyStateView.detach(on: self.view)
            return
        }
        EmptyStateView.attach(on: self.view, message: "Empty".loc)
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
            syncController.purge(note: note) { [weak self] in
                self?.selectedNote = nil
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unRegisterAllNotification()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        syncController.unsetTrashUIRefreshDelegate()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? DetailViewController,
            let note = sender as? Note {
            des.note = note
            des.state = .trash
            des.syncController = syncController
            return
        }
    }
    
    internal func noteViewModel(indexPath: IndexPath) -> NoteViewModel {
        let note = syncController.trashResultsController.object(at: indexPath)
        return NoteViewModel(note: note, viewController: self)
    }
    

    @IBAction func restoreAll(_ sender: Any) {
        Alert.restoreAll(from: self) { [weak self] in
            self?.syncController.restoreAll()
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
    
    @IBAction func deleteAll(_ sender: Any) {
        Alert.deleteAll(from: self) { [weak self] in
            self?.syncController.purgeAll()
            
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
                syncController.increaseTrashFetchLimit(count: 50)
                try? syncController.trashResultsController.performFetch()
                collectionView.reloadData()
            }
        }
    }
    
    override func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        let note = notes[indexPath.row].note
        let noteViewModel = NoteViewModel(note: note, viewController: self)
        
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: noteViewModel.note.reuseIdentifier, for: indexPath) as! ViewModelAcceptable & Refreshable & SyncControllable & CollectionViewCell
        
        cell.viewModel = noteViewModel
        cell.refreshDelegate = self
        cell.syncController = syncController
        return cell
    }
    
    override func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return notes.count
    }
    
    override func numberOfSections(in collectionView: CollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: CollectionView, didSelectItemAt indexPath: IndexPath) {
        let note = notes[indexPath.row].note
        selectedNote = note
        note.didSelectItem(collectionView: collectionView, fromVC: self)
    }
    
    override func collectionView(_ collectionView: CollectionView, didDeselectItemAt indexPath: IndexPath) {
        let note = notes[indexPath.row].note
        note.didDeselectItem(collectionView: collectionView, fromVC: self)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ReusableView", for: indexPath)
        return reusableView
    }
    
}

extension TrashCollectionViewController: CollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, insetForSectionAt section: Int) -> EdgeInsets {
        return syncController.trashResultsController.fetchedObjects?.first?.sectionInset(view: collectionView) ?? EdgeInsets(top: 0, left: 8, bottom: toolHeight, right: 8)
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let note = syncController.trashResultsController.object(at: indexPath)
        return note.size(view: collectionView)
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let firstIndexPathInSection = IndexPath(item: 0, section: section)
        guard let count = syncController.trashResultsController.sections?[section].numberOfObjects, count != 0 else { return 0 }
        let note = syncController.trashResultsController.object(at: firstIndexPathInSection)
        return note.minimumLineSpacing
    }
    
    func collectionView(_ collectionView: CollectionView, layout collectionViewLayout: CollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let firstIndexPathInSection = IndexPath(item: 0, section: section)
        guard let count = syncController.trashResultsController.sections?[section].numberOfObjects, count != 0 else { return 0 }
        let note = syncController.trashResultsController.object(at: firstIndexPathInSection)
        return note.minimumInteritemSpacing
    }
}

extension TrashCollectionViewController: UIRefreshDelegate {
    func refreshUI(with target: [NoteWrapper], animated: Bool, completion: @escaping () -> Void) {
        let changeSet = StagedChangeset(source: notes, target: target)
        DispatchQueue.main.async { [weak self] in
            self?.collectionView.reload(using: changeSet, interrupt: nil) { collection in
                self?.notes = collection
            }
            completion()
        }
    }
}
