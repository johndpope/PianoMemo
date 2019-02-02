//
//  NoteCollectionVC_action.swift
//  Piano
//
//  Created by Kevin Kim on 04/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension NoteCollectionViewController {
    @objc func pasteboardChanged() {
        if Pasteboard.general.hasStrings {
//            clipboardView.isHidden = false
        }
    }

    @IBAction func tapPaste(_ sender: Button) {
        if Pasteboard.general.hasStrings {
            //TODO: create Note
            //TODO: hidden PasteboardView

        } else {
            transparentNavigationController?.show(message: "There's no text on Clipboard. 😅".loc, textColor: Color.white, color: Color.redNoti)
        }
    }

    // MARK: Normal for All
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

    @IBAction func tapAlignment(_ sender: Any) {

    }

    // MARK: Edit for All
    @IBAction func tapMerge(_ sender: Any) {

    }

    @IBAction func tapPin(_ sender: Any) {
        //TODO: 이미지(고정혹은 고정취소)에 따라서 처리
    }

    @IBAction func tapLock(_ sender: Any) {
        //TODO: 이미지(잠금 혹은 잠금해제)에 따라서 처리
    }

    @IBAction func tapMove(_ sender: Any) {
        performSegue(withIdentifier: MoveFolderCollectionViewController.identifier, sender: nil)
    }

    @IBAction func tapTrash(_ sender: Any) {

    }

    // MARK: Normal for Trash
    @IBAction func tapRemoveAll(_ sender: Any) {

    }

    @IBAction func tapRestoreAll(_ sender: Any) {

    }

    // MARK: Edit for Trash
    @IBAction func tapRemove(_ sender: Any) {

    }

    @IBAction func tapRestore(_ sender: Any) {

    }

    @IBAction func tapBackground(_ sender: TapGestureRecognizer) {
        print(sender)
    }

}
