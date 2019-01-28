//
//  NoteCollectionVC_business.swift
//  Piano
//
//  Created by Kevin Kim on 17/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation
import CoreData

extension NoteCollectionViewController {
    //최초 1번만 세팅하면 되는 로직들
    internal func setup() {
        guard let noteHandler = noteHandler else { return }
        navigationItem.rightBarButtonItem = self.editButtonItem
        noteCollectionState = .all
        setupBackgroundView()

        resultsController = NSFetchedResultsController(
            fetchRequest: Note.masterRequest,
            managedObjectContext: noteHandler.context,
            sectionNameKeyPath: nil,
            cacheName: "Note"
        )
        resultsController.delegate = self

        do {
            try resultsController.performFetch()
        } catch {
            print(error)
        }
        collectionView.reloadData()

    }

    internal func deleteEmptyVisibleNotes() {
        guard let noteHandler = noteHandler else { return }
        collectionView.visibleCells.forEach {
            guard let indexPath = collectionView.indexPath(for: $0) else { return }
            collectionView.deselectItem(at: indexPath, animated: true)
            let note = resultsController.object(at: indexPath)
            if note.content?.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
                noteHandler.purge(notes: [note])
            }
        }
    }

    internal func setMoreBtnHidden(_ editing: Bool) {
        //more btn 해제
        collectionView.visibleCells.forEach {
            ($0 as? NoteCollectionViewCell)?.moreButton.isHidden = editing
        }
    }

    internal func deselectSelectedItems() {
        //선택된 것들 해제
        collectionView.indexPathsForSelectedItems?.forEach({ (indexPath) in
            collectionView.deselectItem(at: indexPath, animated: true)
        })
    }

    internal func setResultsController(state: NoteCollectionState) {
        guard let noteHandler = noteHandler else { return }
//        NSFetchedResultsController<Note>.deleteCache(withName: "All Notes")
        resultsController = NSFetchedResultsController(
            fetchRequest: state.noteRequest,
            managedObjectContext: noteHandler.context,
            sectionNameKeyPath: nil,
            cacheName: state.cache)
        resultsController.delegate = self

        fetchAndReloadData()
    }

    private func fetchAndReloadData() {
        do {
            try resultsController.performFetch()
            collectionView.reloadData()
        } catch {
            print(error.localizedDescription)
        }
    }
}

extension NoteCollectionViewController {
    private func setupBackgroundView() {
        //TODO: 백그라운드 터치했을 때 튜토리얼 보여주는 이벤트 적용하기
        let view = View()
        view.backgroundColor = .clear
        let tapGestureRecognizer = TapGestureRecognizer(target: self, action: #selector(tapBackground(_:)))
        view.addGestureRecognizer(tapGestureRecognizer)
        self.collectionView.backgroundView = view
    }

    private func setupMigration() {
        //TODO: 이 부분 해결해야함
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

    }
}
