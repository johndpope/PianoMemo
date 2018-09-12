//
//  MainWindowController.swift
//  LightMac
//
//  Created by hoemoon on 06/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import AppKit

class MainWindowController: NSWindowController {
    override func windowWillLoad() {
        super.windowWillLoad()
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.setContentSize(NSSize(width: 500, height: 500))
        window?.center()
    }
}
