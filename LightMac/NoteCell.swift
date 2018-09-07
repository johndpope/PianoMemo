//
//  NoteCell.swift
//  LightMac
//
//  Created by hoemoon on 07/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Cocoa

class NoteCell: NSCollectionViewItem {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
    }
}
