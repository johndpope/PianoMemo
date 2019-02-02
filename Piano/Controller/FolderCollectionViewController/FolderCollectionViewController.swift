//
//  FolderCollectionViewController.swift
//  Piano
//
//  Created by Kevin Kim on 09/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit
import CoreData

typealias NoteState = NoteCollectionViewController.NoteCollectionState

class FolderCollectionViewController: UICollectionViewController {
    var folderhandler: FolderHandlable?
    internal var resultsController: NSFetchedResultsController<Folder>!

    lazy var alertController: UIAlertController = {
        let controller = UIAlertController(title: "타이틀", message: "메시지", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        let create = UIAlertAction(title: "생성", style: .default) { [weak self] _ in
            guard let self = self,
                let folderHandler = self.folderhandler,
                let input = controller.textFields?.first?.text else { return }
            folderHandler.create(name: input) { _ in
                controller.dismiss(animated: true)
                controller.textFields?.first?.text = ""
            }
        }
        create.isEnabled = false
        controller.addAction(cancel)
        controller.addAction(create)
        controller.addTextField { textField in
            textField.placeholder = "폴더 이름"
            textField.returnKeyType = .done
            textField.enablesReturnKeyAutomatically = true
            textField.addTarget(self, action: #selector(self.alertInputDidChange(_:)), for: .editingChanged)
        }
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    func setup() {
        do {
            guard let context = folderhandler?.context else { return }
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

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return resultsController.sections?[section].numberOfObjects ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FolderCollectionViewCell.reuseIdentifier, for: indexPath) as? FolderCollectionViewCell else { return UICollectionViewCell() }

        let folder = resultsController.object(at: indexPath)
        cell.folder = folder
        cell.folderCollectionVC = self
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let folder = resultsController.object(at: indexPath)
        guard let noteCollectionVC = (presentingViewController as? UINavigationController)?.topViewController as? NoteCollectionViewController else { return }
        noteCollectionVC.noteCollectionState = .folder(folder)
        dismiss(animated: true)
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: FolderCollectionHeaderView.reuseIdentifier,
            for: indexPath
        )
        (header as? FolderCollectionHeaderView)?.setup(delegate: self, context: folderhandler?.context)

        return header
    }
}

extension FolderCollectionViewController: SystemFolderViewDelegate {
    func tapSystemFolder(state: NoteCollectionViewController.NoteCollectionState) {
        guard let noteCollectionVC = (presentingViewController as? UINavigationController)?.topViewController as? NoteCollectionViewController else { return }
        noteCollectionVC.noteCollectionState = state
        dismiss(animated: true)
    }
}

extension FolderCollectionViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
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
                    let folder = controller.object(at: indexPath) as? Folder,
                    let cell = collectionView.cellForItem(at: indexPath) as? FolderCollectionViewCell else { return }
                cell.folder = folder
            case .move:
                guard let indexPath = indexPath,
                    let newIndexPath = newIndexPath else { return }
                collectionView.moveItem(at: indexPath, to: newIndexPath)

            }
        }, completion: nil)
    }
}
