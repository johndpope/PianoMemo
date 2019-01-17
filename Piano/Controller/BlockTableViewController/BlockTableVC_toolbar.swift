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
    var copyBtnTag: Int { return 1000 }
    var cutBtnTag: Int { return 1001 }
    var deleteBtnTag: Int { return 1002 }
    
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
        let cutBtn = BarButtonItem(image: #imageLiteral(resourceName: "cut"), style: .plain, target: self, action: #selector(tapCut(_:)))
        let deleteBtn = BarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(tapDelete(_:)))
        let marginBtn = BarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        marginBtn.width = 16
        let flexibleBtn = BarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        return [screenAreaBtn, flexibleBtn, copyBtn, marginBtn, cutBtn, marginBtn, deleteBtn]
    }
    
    var trashToolbarBtns: [BarButtonItem] {
        let permanentDeleteBtn = BarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(tapPermanentDelete(_:)))
        let restoreBtn = BarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(tapRestore(_:)))
        let flexibleBtn = BarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        return [permanentDeleteBtn, flexibleBtn, restoreBtn]
    }
}
