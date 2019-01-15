//
//  NoteCollectionVC_action.swift
//  Piano
//
//  Created by Kevin Kim on 04/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension NoteCollectionViewController {
    
    @IBAction func tapEdit(_ sender: BarButtonItem) {
        //컬렉션뷰가 edit이면,
        setEditState(!collectionView.isEditable)
        
    }
    
    internal func setEditState(_ bool: Bool) {
        collectionView.isEditable = bool
        collectionView.allowsMultipleSelection = bool
        navigationItem.rightBarButtonItem?.title = bool ? "Done".loc : "Select".loc
        mainToolbar.isHidden = bool
        
        //more btn 해제
        collectionView.visibleCells.forEach {
            ($0 as? NoteCollectionViewCell)?.moreButton.isHidden = bool
        }
        
        //선택된 것들 해제
        collectionView.indexPathsForSelectedItems?.forEach({ (indexPath) in
            collectionView.deselectItem(at: indexPath, animated: true)
        })
        
        setToolbarBtnsEnabled()
    }
    
    @IBAction func tapMerge(_ sender: BarButtonItem) {
        
    }
    
    @IBAction func tapPin(_ sender: BarButtonItem) {
        
    }
    
    @IBAction func tapLock(_ sender: BarButtonItem) {
        
    }
    
    @IBAction func tapTrash(_ sender: BarButtonItem) {
        
    }
    
    @IBAction func tapMove(_ sender: BarButtonItem) {
        
    }
    
    
}

extension NoteCollectionViewController {
    
    internal func setToolbarBtnsEnabled() {
        //선택된 노트의 갯수를 체크해서, enable 세팅
        //pin은 선택된 메모들이 모두 고정이면 고정 취소의 타이틀과 기능을 해야한다.
        //lock은 선택된 메모들이 모두 잠금이면, 잠금 취소의 타이틀과 기능을 해야한다.
        //merge는 2개 이상일 때에만 enabled
        
        guard let indexPaths = collectionView.indexPathsForSelectedItems else { return }
        
        let count = indexPaths.count
        
        mergeBarBtn.isEnabled = count > 1
        pinBarBtn.isEnabled = count > 0
        lockBarBtn.isEnabled = count > 0
        folderBarBtn.isEnabled = count > 0
        trashBarBtn.isEnabled = count > 0
        
        let notes = indexPaths.map { return resultsController.object(at: $0) }
        
        
        let pinnedCount = notes.filter{ $0.isPinned == 1 }.count
        if count == pinnedCount, count != 0 {
            //TODO: 핀 취소하는 이미지 요청
            pinBarBtn.image = #imageLiteral(resourceName: "noclipboardToolbar")
        } else {
            pinBarBtn.image = #imageLiteral(resourceName: "yesclipboardToolbar")
        }
        
        let lockedCount = notes.filter { $0.isLocked == true }.count
        if count == lockedCount, count != 0 {
            //TODO: 잠금 취소하는 이미지 요청
            lockBarBtn.image = #imageLiteral(resourceName: "noclipboardToolbar")
        } else {
            lockBarBtn.image = #imageLiteral(resourceName: "yesclipboardToolbar")
        }
        
    }
}
