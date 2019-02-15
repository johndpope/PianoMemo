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

    /// 선택된 노트에 따라 Toolbar의 아이템을 업데이트하는 함수
    /// - 선택된 노트의 갯수를 체크해서, enable 세팅
    /// - pin은 선택된 메모들이 모두 고정이면 고정 취소의 타이틀과 기능을 해야한다.
    /// - lock은 선택된 메모들이 모두 잠금이면, 잠금 취소의 타이틀과 기능을 해야한다.
    /// - merge는 2개 이상일 때에만 enabled
    internal func updateToolbarItems() {

        guard let indexPaths = collectionView.indexPathsForSelectedItems else { return }
        let notes = indexPaths.map { return resultsController.object(at: $0) }

        let mergeBarBtn = toolbarItems?.first(where: { $0.tag == mergeBtnTag })
        mergeBarBtn?.isEnabled = notes.count > 1

        let otherBarBtns = toolbarItems?.filter { $0.tag > mergeBtnTag }
        otherBarBtns?.forEach { $0.isEnabled = notes.count > 0 }

        let pinBarBtn = toolbarItems?.first(where: { $0.tag == pinBtnTag })
        let pinnedCount = notes.filter { $0.isPinned == 1 }.count
        if notes.count == pinnedCount, notes.count != 0 {
            pinBarBtn?.action = #selector(tapUnpin(_:))
            pinBarBtn?.image = #imageLiteral(resourceName: "unpin")
        } else {
            pinBarBtn?.action = #selector(tapPin(_:))
            pinBarBtn?.image = #imageLiteral(resourceName: "pin")
        }

        let lockBarBtn = toolbarItems?.first(where: { $0.tag == lockBtnTag })
        let lockedCount = notes.filter { $0.isLocked == true }.count
        if notes.count == lockedCount, notes.count != 0 {
            pinBarBtn?.action = #selector(tapUnlock(_:))
            lockBarBtn?.image = #imageLiteral(resourceName: "unlock")
        } else {
            pinBarBtn?.action = #selector(tapLock(_:))
            lockBarBtn?.image = #imageLiteral(resourceName: "lock")
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
}

extension NoteCollectionViewController {
    private var allToolbarBtnsForNormal: [BarButtonItem] {
        let collectionBtn = BarButtonItem(image: #imageLiteral(resourceName: "Collection"), style: .plain, target: self, action: #selector(tapCollection(_:)))
        let writeNowBtn = BarButtonItem(title: "Write Now".loc, style: .plain, target: self, action: #selector(tapWriteNow(_:)))
        let fixBtn = BarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixBtn.width = 20
        return [collectionBtn, writeNowBtn, fixBtn]
    }

    private var allToolbarBtnsForEditing: [BarButtonItem] {
        let mergeBtn = BarButtonItem(image: #imageLiteral(resourceName: "merge"), style: .plain, target: self, action: #selector(tapMerge(_:)))
        mergeBtn.tag = mergeBtnTag
        let pinBtn = BarButtonItem(image: #imageLiteral(resourceName: "pin"), style: .plain, target: self, action: #selector(tapPin(_:)))
        pinBtn.tag = pinBtnTag
        let lockBtn = BarButtonItem(image: #imageLiteral(resourceName: "lock"), style: .plain, target: self, action: #selector(tapLock(_:)))
        lockBtn.tag = lockBtnTag
        let moveBtn = BarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(tapMove(_:)))
        moveBtn.tag = moveBtnTag
        let trashBtn = BarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(tapTrash(_:)))
        trashBtn.tag = trashBtnTag
        let flexibleBtn = BarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        return [mergeBtn, flexibleBtn, pinBtn, flexibleBtn, lockBtn, flexibleBtn, moveBtn, flexibleBtn, trashBtn]
    }

    private var removedToolbarBtnsForNormal: [BarButtonItem] {
        let settingBtn = BarButtonItem(image: #imageLiteral(resourceName: "Filter"), style: .plain, target: self, action: #selector(tapSetting(_:)))
        //let searchBtn = BarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(tapSearch(_:)))
        //let folderBtn = BarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(tapFolder(_:)))
        let removeAllBtn = BarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(tapRemoveAll(_:)))
        let allRestoreBtn = BarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(tapRestoreAll(_:)))
        let flexibleBtn = BarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        return [settingBtn, flexibleBtn, flexibleBtn, flexibleBtn, removeAllBtn, flexibleBtn, allRestoreBtn]
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
