//
//  NoteCollectionVC_toolbar.swift
//  Piano
//
//  Created by Kevin Kim on 18/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation
import CoreGraphics

extension NoteCollectionViewController {
    internal var toolbarBtnSource: [BarButtonItem] {
        switch noteCollectionState {
        case .all, .folder, .locked:
            return isEditing ? allToolbarBtnsForEditing : allToolbarBtnsForNormal
        case .removed:
            return isEditing ? removedToolbarBtnsForEdit : removedToolbarBtnsForNormal
        }
    }

    internal func setToolbarBtnsEnabled() {
        //선택된 노트의 갯수를 체크해서, enable 세팅
        //pin은 선택된 메모들이 모두 고정이면 고정 취소의 타이틀과 기능을 해야한다.
        //lock은 선택된 메모들이 모두 잠금이면, 잠금 취소의 타이틀과 기능을 해야한다.
        //merge는 2개 이상일 때에만 enabled

        guard let indexPaths = collectionView.indexPathsForSelectedItems else { return }

        let count = indexPaths.count

        let mergeBarBtn = toolbarItems?.first(where: { $0.tag == mergeBtnTag })
        mergeBarBtn?.isEnabled = count > 1

        let restBarBtns = toolbarItems?.filter { $0.tag > mergeBtnTag }
        restBarBtns?.forEach { $0.isEnabled = count > 0 }

        let pinBarBtn = toolbarItems?.first(where: { $0.tag == pinBtnTag })

        let notes = indexPaths.map { return resultsController.object(at: $0) }
        let pinnedCount = notes.filter { $0.isPinned == 1 }.count
        if count == pinnedCount, count != 0 {
            //TODO: 핀 취소하는 이미지 요청
            pinBarBtn?.image = #imageLiteral(resourceName: "noclipboardToolbar")
        } else {
            pinBarBtn?.image = #imageLiteral(resourceName: "Oval")
        }

        let lockedCount = notes.filter { $0.isLocked == true }.count
        let lockBarBtn = toolbarItems?.first(where: { $0.tag == lockBtnTag })
        if count == lockedCount, count != 0 {
            //TODO: 잠금 취소하는 이미지 요청
            lockBarBtn?.image = #imageLiteral(resourceName: "noclipboardToolbar")
        } else {
            lockBarBtn?.image = #imageLiteral(resourceName: "Bag")
        }
    }

}

// MARK: Tag
extension NoteCollectionViewController {
    // MARK: edit for normal
    private var mergeBtnTag: Int { return 1000 }
    private var pinBtnTag: Int { return 1001 }
    private var lockBtnTag: Int { return 1002 }
    private var moveBtnTag: Int { return 1003 }
    private var trashBtnTag: Int { return 1004 }

    // MARK: edit for trash
    private var removeBtnTag: Int { return 1005 }
    private var restoreBtnTag: Int { return 1006 }
    internal var writeNowBtnTag: Int { return 1007 }
}

extension NoteCollectionViewController {

    @objc func tapTypingField(_ sender: Any) {
        
    }
    
    internal func adjustWriteNowBtnForToolbar(writeNowBtn: WriteNowButton? = nil, view: View) {
        
        let btn = writeNowBtn ?? toolbarItems?.first{ $0.tag == writeNowBtnTag }?.customView as? WriteNowButton
        
        guard let writeNowBtn = btn,
            let toolbarHeight = navigationController?.toolbar.bounds.height else { return }
        let safeAreaMargin = view.safeAreaInsets.left + view.safeAreaInsets.right
        let sideBtnsWidth: CGFloat = safeAreaMargin != 0 ? 120 : 100
        let width = view.bounds.width - safeAreaMargin - sideBtnsWidth
        let heightMargin: CGFloat = view.bounds.width > view.bounds.height ? 2 : 6
        let plusHeightMargin: CGFloat = safeAreaMargin != 0 ? 0 : 6
        writeNowBtn.frame.size.width = width
        writeNowBtn.frame.size.height = toolbarHeight - heightMargin - plusHeightMargin
    }
    
    private var allToolbarBtnsForNormal: [BarButtonItem] {
        guard let writeNowBtn = view.createSubviewIfNeeded(WriteNowButton.self) else { return [] }
        writeNowBtn.addTarget(self, action: #selector(tapTypingField(_:)), for: .touchUpInside)
        adjustWriteNowBtnForToolbar(writeNowBtn: writeNowBtn, view: view)
        let writeNowToolbarBtn = BarButtonItem(customView: writeNowBtn)
        writeNowToolbarBtn.tag = writeNowBtnTag
        let folderBtn = BarButtonItem(image: #imageLiteral(resourceName: "Collection"), style: .plain, target: self, action: #selector(tapFolder(_:)))

        let flexibleBtn = BarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let searchBtn = BarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(tapSearch(_:)))
        return [folderBtn, flexibleBtn, writeNowToolbarBtn, flexibleBtn, searchBtn]
    }

    private var allToolbarBtnsForEditing: [BarButtonItem] {
        let mergeBtn = BarButtonItem(image: #imageLiteral(resourceName: "merge"), style: .plain, target: self, action: #selector(tapMerge(_:)))
        mergeBtn.tag = mergeBtnTag
        let pinBtn = BarButtonItem(image: #imageLiteral(resourceName: "Oval"), style: .plain, target: self, action: #selector(tapSetting(_:)))
        pinBtn.tag = pinBtnTag
        let lockBtn = BarButtonItem(image: #imageLiteral(resourceName: "Bag"), style: .plain, target: self, action: #selector(tapSetting(_:)))
        lockBtn.tag = lockBtnTag
        let moveBtn = BarButtonItem(image: #imageLiteral(resourceName: "Collection"), style: .plain, target: self, action: #selector(tapMove(_:)))
        moveBtn.tag = moveBtnTag
        let trashBtn = BarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(tapTrash(_:)))
        trashBtn.tag = trashBtnTag
        let flexibleBtn = BarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        return [mergeBtn, flexibleBtn, pinBtn, flexibleBtn, lockBtn, flexibleBtn, moveBtn, flexibleBtn, trashBtn]
    }

    private var removedToolbarBtnsForNormal: [BarButtonItem] {
        let settingBtn = BarButtonItem(image: #imageLiteral(resourceName: "Filter"), style: .plain, target: self, action: #selector(tapSetting(_:)))
        let searchBtn = BarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(tapSearch(_:)))
        let folderBtn = BarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(tapFolder(_:)))
        let removeAllBtn = BarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(tapRemoveAll(_:)))
        let allRestoreBtn = BarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(tapRestoreAll(_:)))
        let flexibleBtn = BarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        return [settingBtn, flexibleBtn, searchBtn, flexibleBtn, folderBtn, flexibleBtn, removeAllBtn, flexibleBtn, allRestoreBtn]
    }

    private var removedToolbarBtnsForEdit: [BarButtonItem] {
        let removeBtn = BarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(tapRemove(_:)))
        removeBtn.tag = removeBtnTag
        let restoreBtn = BarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(tapRestore(_:)))
        restoreBtn.tag = restoreBtnTag
        let flexibleBtn = BarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        return [removeBtn, flexibleBtn, restoreBtn]
    }
}
