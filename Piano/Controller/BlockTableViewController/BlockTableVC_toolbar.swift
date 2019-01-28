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

    //TODO: 미리알림 등록 버튼
    var reminderBtnTag: Int { return 1004 }

    //상태값이 바뀌어야 하는 버튼들
    var editBtns: [BarButtonItem] {
        return toolbarItems?.filter { $0.tag > 1000 } ?? []
    }

    internal func setupToolbar() {
        switch blockTableState {
        case .normal(let detailState):
            switch detailState {
            case .read, .typing:
                setToolbarItems(normalToolbarBtns, animated: true)
            case .editing:
                setToolbarItems(editToolbarBtns, animated: true)
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
        guard isEditing else { return }
        let count = tableView.indexPathsForSelectedRows?.count ?? 0

        var editBtns: [BarButtonItem] {
            return toolbarItems?.filter { $0.tag > 1000 } ?? []
        }
        editBtns.forEach {
            $0.isEnabled = count > 0
        }
    }

    var normalToolbarBtns: [BarButtonItem] {
        let trashBtn = BarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(tapTrash(_:)))
        let infoBtn = BarButtonItem(image: #imageLiteral(resourceName: "Info"), style: .plain, target: self, action: #selector(tapInfo(_:)))
        let pianoBtn = BarButtonItem(image: #imageLiteral(resourceName: "highlights"), style: .plain, target: self, action: #selector(tapPiano(_:)))
        let shareBtn = BarButtonItem(image: #imageLiteral(resourceName: "theme"), style: .plain, target: self, action: #selector(tapShare(_:)))
        let composeBtn = BarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(tapCompose(_:)))
        let flexibleBtn = BarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        return [trashBtn, flexibleBtn, infoBtn, flexibleBtn, pianoBtn, flexibleBtn, shareBtn, flexibleBtn, composeBtn]
    }

    var pianoToolbarBtns: [BarButtonItem] {
        let doneBtn = BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(tapDonePiano(_:)))
        let flexibleBtn = BarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        return [flexibleBtn, doneBtn, flexibleBtn]
    }

    var editToolbarBtns: [BarButtonItem] {
        let reminderBtn = BarButtonItem(image: #imageLiteral(resourceName: "remind"), style: .plain, target: self, action: #selector(tapReminder(_:)))
        reminderBtn.tag = reminderBtnTag
        reminderBtn.isEnabled = false
        let copyBtn = BarButtonItem(image: #imageLiteral(resourceName: "copy"), style: .plain, target: self, action: #selector(tapCopy(_:)))
        copyBtn.tag = copyBtnTag
        copyBtn.isEnabled = false
        let cutBtn = BarButtonItem(image: #imageLiteral(resourceName: "cut"), style: .plain, target: self, action: #selector(tapCut(_:)))
        cutBtn.tag = cutBtnTag
        cutBtn.isEnabled = false
        let deleteBtn = BarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(tapDelete(_:)))
        deleteBtn.tag = deleteBtnTag
        deleteBtn.isEnabled = false
        let marginBtn = BarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        marginBtn.width = 16
        let flexibleBtn = BarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        return [reminderBtn, flexibleBtn, copyBtn, flexibleBtn, cutBtn, flexibleBtn, deleteBtn]
    }

    var removedToolbarBtns: [BarButtonItem] {
        let permanentDeleteBtn = BarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(tapPermanentDelete(_:)))
        let restoreBtn = BarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(tapRestore(_:)))
        let flexibleBtn = BarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        return [permanentDeleteBtn, flexibleBtn, restoreBtn]
    }
}
