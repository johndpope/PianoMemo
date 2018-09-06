//
//  NoteCell.swift
//  LightMac
//
//  Created by hoemoon on 06/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Cocoa

class NoteCell: NSCollectionViewItem {
    var note: Note? {
        didSet {
            if let note = note, let content = note.content {
                textField?.stringValue = content
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.lightGray.cgColor
    }
}
