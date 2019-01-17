//
//  NoteCollectionVC_action.swift
//  Piano
//
//  Created by Kevin Kim on 04/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension NoteCollectionViewController {
    
    var notEditingToolbarBtns: [BarButtonItem] {
        let settingBtn = BarButtonItem(image: #imageLiteral(resourceName: "setting"), style: .plain, target: self, action: #selector(tapSetting(_:)))
        let searchBtn = BarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(tapSearch(_:)))
        let folderBtn = BarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(tapFolder(_:)))
        let quickBtn = BarButtonItem(image: #imageLiteral(resourceName: "newMemo"), style: .plain, target: self, action: #selector(tapQuick(_:)))
        let composeBtn = BarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(tapCompose(_:)))
        let flexibleBtn = BarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        return [settingBtn, flexibleBtn, searchBtn, flexibleBtn, folderBtn, flexibleBtn, quickBtn, flexibleBtn, composeBtn]
    }
    
    var editingToolbarBtns: [BarButtonItem] {
        let mergeBtn = BarButtonItem(image: #imageLiteral(resourceName: "merge"), style: .plain, target: self, action: #selector(tapMerge(_:)))
        mergeBtn.tag = 1000
        let pinBtn = BarButtonItem(image: #imageLiteral(resourceName: "noclipboardToolbar"), style: .plain, target: self, action: #selector(tapSetting(_:)))
        pinBtn.tag = 1001
        let lockBtn = BarButtonItem(image: #imageLiteral(resourceName: "yesclipboardToolbar"), style: .plain, target: self, action: #selector(tapSetting(_:)))
        lockBtn.tag = 1002
        let moveBtn = BarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(tapMove(_:)))
        moveBtn.tag = 1003
        let trashBtn = BarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(tapTrash(_:)))
        trashBtn.tag = 1004
        let flexibleBtn = BarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        return [mergeBtn, flexibleBtn, pinBtn, flexibleBtn, lockBtn, flexibleBtn, moveBtn, flexibleBtn, trashBtn]
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        collectionView.allowsMultipleSelection = editing
        setToolbarItems(editing ? editingToolbarBtns : notEditingToolbarBtns, animated: true)
        
        //more btn 해제
        collectionView.visibleCells.forEach {
            ($0 as? NoteCollectionViewCell)?.moreButton.isHidden = editing
        }
        
        //선택된 것들 해제
        collectionView.indexPathsForSelectedItems?.forEach({ (indexPath) in
            collectionView.deselectItem(at: indexPath, animated: true)
        })
        
        setToolbarBtnsEnabled()
        
    }
    
    
    @IBAction func tapSetting(_ sender: Any) {
        performSegue(withIdentifier: SettingTableViewController.identifier, sender: nil)
    }
    
    @IBAction func tapSearch(_ sender: Any) {
        performSegue(withIdentifier: SearchViewController.identifier, sender: nil)
    }
    
    @IBAction func tapFolder(_ sender: Any) {
        performSegue(withIdentifier: FolderCollectionViewController.identifier, sender: nil)
    }
    
    @IBAction func tapQuick(_ sender: Any) {
        performSegue(withIdentifier: SmartWritingViewController.identifier, sender: nil)
    }
    
    @IBAction func tapCompose(_ sender: Any) {
        performSegue(withIdentifier: DetailViewController.identifier, sender: nil)
    }
    
    //MARK: For Edit
    @IBAction func tapMerge(_ sender: BarButtonItem) {
        
    }
    
    @IBAction func tapPin(_ sender: BarButtonItem) {
        //TODO: 이미지(고정혹은 고정취소)에 따라서 처리
    }
    
    @IBAction func tapLock(_ sender: BarButtonItem) {
        //TODO: 이미지(잠금 혹은 잠금해제)에 따라서 처리
    }
    
    @IBAction func tapMove(_ sender: BarButtonItem) {
        
    }
    
    @IBAction func tapTrash(_ sender: BarButtonItem) {
        
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
        
        let mergeBarBtn = toolbarItems?.first(where: { $0.tag == 1000 })
        mergeBarBtn?.isEnabled = count > 1
        let restBarBtns = toolbarItems?.filter { $0.tag > 1000 }
        let pinBarBtn = toolbarItems?.first(where: { $0.tag == 1001 })
        let lockBarBtn = toolbarItems?.first(where: { $0.tag == 1002 })
        
        restBarBtns?.forEach {
            $0.isEnabled = count > 0
        }
        
        
        let notes = indexPaths.map { return resultsController.object(at: $0) }
        
        
        let pinnedCount = notes.filter{ $0.isPinned == 1 }.count
        if count == pinnedCount, count != 0 {
            //TODO: 핀 취소하는 이미지 요청
            pinBarBtn?.image = #imageLiteral(resourceName: "noclipboardToolbar")
        } else {
            pinBarBtn?.image = #imageLiteral(resourceName: "yesclipboardToolbar")
        }
        
        let lockedCount = notes.filter { $0.isLocked == true }.count
        if count == lockedCount, count != 0 {
            //TODO: 잠금 취소하는 이미지 요청
            lockBarBtn?.image = #imageLiteral(resourceName: "noclipboardToolbar")
        } else {
            lockBarBtn?.image = #imageLiteral(resourceName: "yesclipboardToolbar")
        }
        
    }
}
