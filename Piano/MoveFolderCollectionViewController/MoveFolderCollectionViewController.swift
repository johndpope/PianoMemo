//
//  MoveFolderViewController.swift
//  Piano
//
//  Created by Kevin Kim on 24/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit
import CoreData

class MoveFolderCollectionViewController: UICollectionViewController {
    var selectedNotes = [Note]()
    internal var resultsController: NSFetchedResultsController<Folder>!

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    func setup() {
        do {
            guard let context = noteHandler?.context else { return }
            let request: NSFetchRequest<Folder> = Folder.fetchRequest()
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                Folder.notMarkedForLocalDeletionPredicate,
                Folder.notMarkedForRemoteDeletionPredicate
                ])
            let order = NSSortDescriptor(key: "order", ascending: false)

            request.sortDescriptors = [order]
            resultsController = NSFetchedResultsController(
                fetchRequest: request,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            try resultsController.performFetch()
            collectionView.reloadData()
        } catch {
            print(error.localizedDescription)
        }
    }

    @IBAction func didTapCancel(_ sender: Any) {
        dismiss(animated: true)
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return resultsController.sections?[section].numberOfObjects ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MoveFolderCollectionViewCell", for: indexPath) as! FolderCollectionViewCell
        let folder = resultsController.object(at: indexPath)
        cell.folder = folder
        return cell
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath) {

        let completion: (Bool) -> Void = { _ in self.dismiss(animated: true) }
        let destination = resultsController.object(at: indexPath)
        noteHandler.move(notes: selectedNotes, to: destination, completion: completion)
        selectedNotes = []
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath) -> UICollectionReusableView {

        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MoveFolderHeaderView.reuseIdentifier,
            for: indexPath
        )
        (header as? MoveFolderHeaderView)?.notes = selectedNotes
        return header
    }
}
