//
//  TextView.swift
//  LightMac
//
//  Created by hoemoon on 11/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import AppKit

class TextView: NSTextView {
    override func cancelOperation(_ sender: Any?) {
        (NSApplication.shared.delegate as? AppDelegate)?.hideWindow(sender)
    }
}
