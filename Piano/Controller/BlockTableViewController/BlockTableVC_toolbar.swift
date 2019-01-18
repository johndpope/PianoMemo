//
//  BlockTableVC_toolbar.swift
//  Piano
//
//  Created by Kevin Kim on 17/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension BlockTableViewController {
    //normal: trash, timer, piano, share, write
    //piano: Done
    //editing: screenArea, copy, cut, delete
    var copyBtnTag: Int { return 1001 }
    var cutBtnTag: Int { return 1002 }
    var deleteBtnTag: Int { return 1003 }
    
    //상태값이 바뀌어야 하는 버튼들
    var editBtns: [BarButtonItem] {
        return toolbarItems?.filter { $0.tag > 1000 } ?? []
    }
    
    internal func setupToolbar() {
        switch blockTableState {
        case .normal(let detailState):
            switch detailState {
            case .editing, .read, .typing:
                setToolbarItems(normalToolbarBtns, animated: true)
            case .piano:
                setToolbarItems(pianoToolbarBtns, animated: true)
            }
        case .removed:
            setToolbarItems(removedToolbarBtns, animated: true)
        }
    }
    
    internal func setToolbarBtnsEnabled() {
        //선택된 블록의 갯수를 체크해서 enable 세팅
        //copy, cut, delete 모두 선택 갯수가 1개 이상이기만 하면 enable을 켜준다.
        
        guard let count = tableView.indexPathsForSelectedRows?.count else { return }
        var editBtns: [BarButtonItem] {
            return toolbarItems?.filter { $0.tag > 1000 } ?? []
        }
        
        //선택된 노트의 갯수를 체크해서, enable 세팅
        //pin은 선택된 메모들이 모두 고정이면 고정 취소의 타이틀과 기능을 해야한다.
        //lock은 선택된 메모들이 모두 잠금이면, 잠금 취소의 타이틀과 기능을 해야한다.
        //merge는 2개 이상일 때에만 enabled
        
//        guard let indexPaths = collectionView.indexPathsForSelectedItems else { return }
//        
//        let count = indexPaths.count
//        
//        let mergeBarBtn = toolbarItems?.first(where: { $0.tag == mergeBtnTag })
//        mergeBarBtn?.isEnabled = count > 1
//        
//        let restBarBtns = toolbarItems?.filter { $0.tag > mergeBtnTag }
//        restBarBtns?.forEach { $0.isEnabled = count > 0 }
//        
//        let pinBarBtn = toolbarItems?.first(where: { $0.tag == pinBtnTag })
//        
//        let notes = indexPaths.map { return resultsController.object(at: $0) }
//        let pinnedCount = notes.filter{ $0.isPinned == 1 }.count
//        if count == pinnedCount, count != 0 {
//            //TODO: 핀 취소하는 이미지 요청
//            pinBarBtn?.image = #imageLiteral(resourceName: "noclipboardToolbar")
//        } else {
//            pinBarBtn?.image = #imageLiteral(resourceName: "yesclipboardToolbar")
//        }
//        
//        let lockedCount = notes.filter { $0.isLocked == true }.count
//        let lockBarBtn = toolbarItems?.first(where: { $0.tag == lockBtnTag })
//        if count == lockedCount, count != 0 {
//            //TODO: 잠금 취소하는 이미지 요청
//            lockBarBtn?.image = #imageLiteral(resourceName: "noclipboardToolbar")
//        } else {
//            lockBarBtn?.image = #imageLiteral(resourceName: "yesclipboardToolbar")
//        }
    }
    
    var normalToolbarBtns: [BarButtonItem] {
        let trashBtn = BarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(tapTrash(_:)))
        let timerBtn = BarButtonItem(image: #imageLiteral(resourceName: "remind"), style: .plain, target: self, action: #selector(tapTimer(_:)))
        let pianoBtn = BarButtonItem(image: #imageLiteral(resourceName: "highlights"), style: .plain, target: self, action: #selector(tapPiano(_:)))
        let shareBtn = BarButtonItem(image: #imageLiteral(resourceName: "theme"), style: .plain, target: self, action: #selector(tapShare(_:)))
        let composeBtn = BarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(tapCompose(_:)))
        let flexibleBtn = BarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        return [trashBtn, flexibleBtn, timerBtn, flexibleBtn, pianoBtn, flexibleBtn, shareBtn, flexibleBtn, composeBtn]
    }
    
    var pianoToolbarBtns: [BarButtonItem] {
        let doneBtn = BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(tapDonePiano(_:)))
        let flexibleBtn = BarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        return [flexibleBtn, doneBtn, flexibleBtn]
    }
    
    var editToolbarBtns: [BarButtonItem] {
        let screenAreaBtn = BarButtonItem(title: "Select screen area".loc, style: .plain, target: self, action: #selector(tapSelectScreenArea(_:)))
        let copyBtn = BarButtonItem(image: #imageLiteral(resourceName: "noclipboardToolbar"), style: .plain, target: self, action: #selector(tapCopy(_:)))
        copyBtn.tag = copyBtnTag
        let cutBtn = BarButtonItem(image: #imageLiteral(resourceName: "cut"), style: .plain, target: self, action: #selector(tapCut(_:)))
        cutBtn.tag = cutBtnTag
        let deleteBtn = BarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(tapDelete(_:)))
        deleteBtn.tag = deleteBtnTag
        let marginBtn = BarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        marginBtn.width = 16
        let flexibleBtn = BarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        return [screenAreaBtn, flexibleBtn, copyBtn, marginBtn, cutBtn, marginBtn, deleteBtn]
    }
    
    var removedToolbarBtns: [BarButtonItem] {
        let permanentDeleteBtn = BarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(tapPermanentDelete(_:)))
        let restoreBtn = BarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(tapRestore(_:)))
        let flexibleBtn = BarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        return [permanentDeleteBtn, flexibleBtn, restoreBtn]
    }
}
