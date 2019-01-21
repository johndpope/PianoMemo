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
    
    internal var noteCollectionState: NoteCollectionState = .all {
        didSet {
            setResultsController(state: noteCollectionState)
            setToolbarItems(toolbarBtns, animated: true)
        }
    }
    
    weak var noteHandler: NoteHandlable!
    weak var folderHadler: FolderHandlable!
    weak var imageHandler: ImageHandlable!
    
    lazy var privateQueue: OperationQueue = {
        return OperationQueue()
    }()
    
    internal var resultsController: NSFetchedResultsController<Note>!

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
    
    @IBAction func tapBackground(_ sender: UITapGestureRecognizer) {
        print(sender)
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
        
        if let des = segue.destination as? BlockTableViewController {
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
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        collectionView.allowsMultipleSelection = editing
        setToolbarItems(toolbarBtns, animated: true)
        setMoreBtnHidden(editing)
        deselectSelectedItems()
        setToolbarBtnsEnabled()
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
        
        if isEditing {
            setToolbarBtnsEnabled()
        } else {
            let note = resultsController.object(at: indexPath)
            performSegue(withIdentifier: BlockTableViewController.identifier, sender: note)
        }
        
    }
    
    override func collectionView(_ collectionView: CollectionView, didDeselectItemAt indexPath: IndexPath) {
        setToolbarBtnsEnabled()
    }
    

}
