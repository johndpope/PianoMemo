//
//  NoteCollectionViewController.swift
//  Piano
//
//  Created by Kevin Kim on 16/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit
import CoreData

extension ViewController {
    var noteHandler: NoteHandlable! {
        return (UIApplication.shared.delegate as! AppDelegate).noteHandler
    }

    var imageHandler: ImageHandlable! {
        return (UIApplication.shared.delegate as! AppDelegate).imageHandler
    }

    var folderHandler: FolderHandlable! {
        return (UIApplication.shared.delegate as! AppDelegate).folderHandler
    }

    var imageCache: NSCache<NSString, UIImage> {
        return (UIApplication.shared.delegate as! AppDelegate).imageCache
    }

    var persistentContainer: NSPersistentContainer {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    }
}

class NoteCollectionViewController: UICollectionViewController {

    internal var noteCollectionState: NoteCollectionState = .all {
        didSet {
            setResultsController(state: noteCollectionState)
            setToolbarItems(toolbarBtnSource, animated: true)
        }
    }

    var isFromTutorial: Bool = false

    lazy var searchController = UISearchController(searchResultsController: nil)
    lazy var privateQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    internal var resultsController: NSFetchedResultsController<Note>!

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        registerAllNotification()
    }

    deinit {
        unRegisterAllNotification()
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

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if let des = segue.destination as? BlockTableViewController {
            des.note = sender as? Note
            return
        }

        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? ExpireDateViewController,
            let note = sender as? Note {
            vc.note = note
            return
        }

        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? MoveFolderCollectionViewController {
            vc.selectedNotes = (collectionView.indexPathsForSelectedItems ?? [])
                .map { resultsController.object(at: $0) }
            return
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        collectionView.allowsMultipleSelection = editing
        setToolbarItems(toolbarBtnSource, animated: true)
        setMoreBtnHidden(editing)
        deselectSelectedItems()
        updateToolbarItems()
    }

    // MARK: UICollectionViewDataSource
    override func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NoteCollectionViewCell.reuseIdentifier, for: indexPath) as? NoteCollectionViewCell else { return CollectionViewCell() }

        let note = resultsController.object(at: indexPath)
        cell.noteCollectionVC = self

        if isFiltering {
            cell.setup(note: note, keyword: searchController.searchBar.text)
        } else {
            cell.setup(note: note)
        }
        return cell
    }

    override func numberOfSections(in collectionView: CollectionView) -> Int {
        return resultsController.sections?.count ?? 0
    }

    override func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return resultsController.sections?[section].numberOfObjects ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return NoteCollectionViewCell.customSelectors.contains(where: { (selector, _) -> Bool in
            return action == selector
        })
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {

    }

    override func collectionView(_ collectionView: CollectionView, didSelectItemAt indexPath: IndexPath) {

        if isEditing {
            updateToolbarItems()
        } else {
            let note = resultsController.object(at: indexPath)
            guard note.isLocked else {
                performSegue(withIdentifier: BlockTableViewController.identifier, sender: note)
                return
            }
            let reason = "View locked note".loc
            Authenticator.requestAuth(reason: reason, success: {
                self.performSegue(withIdentifier: BlockTableViewController.identifier, sender: note)
            }, failure: { _ in

            }, notSet: {
                self.performSegue(withIdentifier: BlockTableViewController.identifier, sender: note)
            })
            collectionView.deselectItem(at: indexPath, animated: true)
        }
    }

    override func collectionView(_ collectionView: CollectionView, didDeselectItemAt indexPath: IndexPath) {
        updateToolbarItems()
    }

}
