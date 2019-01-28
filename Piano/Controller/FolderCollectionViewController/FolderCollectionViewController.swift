//
//  FolderCollectionViewController.swift
//  Piano
//
//  Created by Kevin Kim on 09/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit
import CoreData
import DifferenceKit

struct FolderWrapper {
    let name: String
    let count: Int
}

class FolderCollectionViewController: UICollectionViewController {
    var dataSource: [[FolderWrapper]] = []
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
            let noteRequest: NSFetchRequest<Note> = Note.fetchRequest()
            noteRequest.predicate = NSPredicate(value: true)
            let allCount = try context.count(for: noteRequest)
            noteRequest.predicate = NSPredicate(format: "isLocked == true")
            let lockedCount = try context.count(for: noteRequest)
            noteRequest.predicate = NSPredicate(format: "isRemoved == true")
            let removedCount = try context.count(for: noteRequest)

            dataSource.append(
                [FolderWrapper(name: "모든 메모", count: allCount),
                 FolderWrapper(name: "잠긴 메모", count: lockedCount),
                 FolderWrapper(name: "삭제된 메모", count: removedCount)
            ])

            resultsController = NSFetchedResultsController(
                fetchRequest: Folder.listRequest,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: "Folder"
            )
            resultsController.delegate = self
            try resultsController.performFetch()
            guard let fetched = resultsController.fetchedObjects else { return }
            dataSource.append(fetched.compactMap { $0.wrapped })
            collectionView.reloadData()

        } catch {
            print(error.localizedDescription)
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return dataSource.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return dataSource[section].count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FolderCollectionViewCell.reuseIdentifier, for: indexPath) as? FolderCollectionViewCell else { return UICollectionViewCell() }

        cell.folder = dataSource[indexPath.section][indexPath.item]
        cell.folderCollectionVC = self

        cell.moreButton.isHidden = indexPath.section == 0

        // Configure the cell

        return cell
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
                collectionView.deleteItems(at: [indexPath.converted])

            case .insert:
                guard let newIndexPath = newIndexPath, let wrapped = (anObject as? Folder)?.wrapped else { return }
                dataSource[newIndexPath.converted.section].append(wrapped)
                collectionView.insertItems(at: [newIndexPath.converted])

            case .update:
                guard let indexPath = indexPath,
                    let wrapped = (anObject as? Folder)?.wrapped,
                    let cell = collectionView.cellForItem(at: indexPath.converted) as? FolderCollectionViewCell else { return }
                cell.folder = wrapped

            case .move:
                guard let indexPath = indexPath,
                    let newIndexPath = newIndexPath else { return }
                collectionView.moveItem(at: indexPath.converted, to: newIndexPath.converted)
            }
        }, completion: nil)

    }
}

extension IndexPath {
    var converted: IndexPath {
        return IndexPath(item: self.row, section: self.section + 1)
    }
}

extension Folder {
    var wrapped: FolderWrapper? {
        guard let context = self.managedObjectContext else { return nil }
        var wrapper: FolderWrapper?
        context.performAndWait {
            if let name = self.name, let noteCount = self.notes?.count {
                wrapper = FolderWrapper(name: name, count: noteCount)
            }
        }
        return wrapper
    }
}
