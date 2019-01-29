//
//  MoveFolderViewController.swift
//  Piano
//
//  Created by Kevin Kim on 24/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit
import CoreData

class MoveFolderViewController: UIViewController {
    var dataSource: [[FolderWrapper]] = []
    var selectedNotes = [Note]()
    var noteHandler: NoteHandlable?

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var headerView: MoveFolderHeaderView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        headerView.setup(notes: selectedNotes)
    }

    func setup() {
        do {
            guard let context = noteHandler?.context else { return }
            let noteRequest: NSFetchRequest<Note> = Note.fetchRequest()
            noteRequest.predicate = NSPredicate(value: true)
            let allCount = try context.count(for: noteRequest)
            noteRequest.predicate = NSPredicate(format: "isLocked == true")
            let lockedCount = try context.count(for: noteRequest)
            noteRequest.predicate = NSPredicate(format: "isRemoved == true")
            let removedCount = try context.count(for: noteRequest)

            dataSource.append(
                [FolderWrapper(name: "모든 메모", count: allCount, state: .all),
                 FolderWrapper(name: "잠긴 메모", count: lockedCount, state: .locked),
                 FolderWrapper(name: "삭제된 메모", count: removedCount, state: .removed)
                ])

            let fetched = try context.fetch(Folder.listRequest)

            dataSource.append(fetched.compactMap { $0.wrapped })
            collectionView.reloadData()

        } catch {
            print(error.localizedDescription)
        }
    }

    @IBAction func didTapCancel(_ sender: Any) {
        dismiss(animated: true)
    }
}

extension MoveFolderViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource[section].count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MoveFolderCollectionViewCell", for: indexPath) as! FolderCollectionViewCell
        cell.folder = dataSource[indexPath.section][indexPath.item]
        return cell
    }
}

extension MoveFolderViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let completion: (Bool) -> Void = { _ in self.dismiss(animated: true) }
        guard let noteHandler = noteHandler else { return }
        let selected = dataSource[indexPath.section][indexPath.item]
        switch selected.state {
        case .all:
            noteHandler.neutralize(notes: selectedNotes, completion: completion)
        case .locked:
            noteHandler.lockNote(notes: selectedNotes, completion: completion)
        case .removed:
            noteHandler.remove(notes: selectedNotes, completion: completion)
        case .folder(let folder):
            noteHandler.move(notes: selectedNotes, to: folder, completion: completion)
        }
    }
}
