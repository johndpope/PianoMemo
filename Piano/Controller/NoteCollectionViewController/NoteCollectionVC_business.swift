//
//  NoteCollectionVC_business.swift
//  Piano
//
//  Created by Kevin Kim on 17/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension NoteCollectionViewController {
    //최초 1번만 세팅하면 되는 로직들
    internal func setup() {
        navigationItem.rightBarButtonItem = self.editButtonItem

        //TODO: 백그라운드 터치했을 때 튜토리얼 보여주는 이벤트 적용하기
        let view = View()
        view.backgroundColor = .clear
        let tapGestureRecognizer = TapGestureRecognizer(target: self, action: #selector(tapBackground(_:)))
        view.addGestureRecognizer(tapGestureRecognizer)
        self.collectionView.backgroundView = view
        
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

    }
    
    internal func loadData() {
        //TODO: resultsController perform 시키고, reloadData
        
        do {
            try resultsController.performFetch()
            collectionView.reloadData()
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    internal func deleteEmptyVisibleNotes() {
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
}
