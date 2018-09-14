//
//  MasterWindow.swift
//  LightMac
//
//  Created by hoemoon on 10/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import AppKit

class MasterWindow: NSWindow {
    override var canBecomeMain: Bool {
        return true
    }

    override var canBecomeKey: Bool {
        return true
    }
}
