//
//  NoteCollectionViewController.swift
//  Piano
//
//  Created by Kevin Kim on 16/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit
import CoreData

class NoteCollectionViewController: UICollectionViewController {
    
    weak var noteHandler: NoteHandlable!
    weak var folderHadler: FolderHandlable!
    weak var imageHandler: ImageHandlable!
    
    lazy var privateQueue: OperationQueue = {
        return OperationQueue()
    }()
    
    lazy var resultsController: NSFetchedResultsController<Note> = {
        let controller = NSFetchedResultsController(
            fetchRequest: Note.masterRequest,
            managedObjectContext: noteHandler.context,
            sectionNameKeyPath: nil,
            cacheName: "Note")
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        if noteHandler == nil {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                self.noteHandler = appDelegate.noteHandler
            }
        } else {
            setup()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerAllNotification()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unRegisterAllNotifications()
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        self.setup()
        super.decodeRestorableState(with: coder)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        deleteEmptyVisibleNotes()
        EditingTracker.shared.setEditingNote(note: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? SmartWritingViewController {
            vc.noteHandler = noteHandler
            return
        }
        
        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? SettingTableViewController {
            vc.noteHandler = noteHandler
            return
        }
        
        if let des = segue.destination as? DetailViewController {
            des.noteHandler = noteHandler
            des.note = sender as? Note
            return
        }
        
        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? SearchViewController {
            vc.noteHandler = noteHandler
            return
        }
    }

    // MARK: UICollectionViewDataSource
    override func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NoteCollectionViewCell.reuseIdentifier,
                                                            for: indexPath) as? NoteCollectionViewCell else { return CollectionViewCell() }
        
        let note = resultsController.object(at: indexPath)
        cell.note = note
        cell.noteCollectionVC = self
        cell.moreButton.isHidden = self.isEditing
        return cell
    }
    
    override func numberOfSections(in collectionView: CollectionView) -> Int {
        return resultsController.sections?.count ?? 0
    }
    
    override func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return resultsController.sections?[section].numberOfObjects ?? 0
    }

    override func collectionView(_ collectionView: CollectionView, didSelectItemAt indexPath: IndexPath) {
        setToolbarBtnsEnabled()
    }
    
    override func collectionView(_ collectionView: CollectionView, didDeselectItemAt indexPath: IndexPath) {
        setToolbarBtnsEnabled()
    }
    

}

extension NoteCollectionViewController {
    private func setup() {
        resultsController.delegate = self
        navigationItem.rightBarButtonItem = self.editButtonItem
        
        //TODO: 마이그레이션 코드 넣어야 함.
        
        //        if !UserDefaults.didContentMigration() {
        //            let bulk = BulkUpdateOperation(request: Note.allfetchRequest(), context: viewContext) { [weak self] in
        //                guard let self = self else { return }
        //                self.loadData()
        //                UserDefaults.doneContentMigration()
        //            }
        //            privateQueue.addOperation(bulk)
        //        } else {
        //            self.loadData()
        //        }
        
        self.loadData()
        
        //TODO: collectionView의 bottomInset값 세팅하기
    }
    
    private func loadData() {
        //TODO: resultsController perform 시키고, reloadData
        
        do {
            try resultsController.performFetch()
            collectionView.reloadData()
        } catch {
            print(error.localizedDescription)
        }
        
        
    }
    
    private func registerAllNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(pasteboardChanged), name: UIPasteboard.changedNotification, object: nil)
    }
    
    @objc func pasteboardChanged() {
        //TODO: pasteboardView를 없앨지 결정
    }
    
    private func unRegisterAllNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func deleteEmptyVisibleNotes() {
        collectionView.visibleCells.forEach {
            guard let indexPath = collectionView.indexPath(for: $0) else { return }
            collectionView.deselectItem(at: indexPath, animated: true)
            let note = resultsController.object(at: indexPath)
            if note.content?.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
                noteHandler.purge(notes: [note])
            }
        }
    }
}
