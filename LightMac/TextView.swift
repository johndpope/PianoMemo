//
//  TextView.swift
//  LightMac
//
//  Created by hoemoon on 11/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import AppKit

class TextView: NSTextView {
    weak var keyDownDelegate: KeyDownDelegate?

    override func cancelOperation(_ sender: Any?) {
        (NSApplication.shared.delegate as? AppDelegate)?.hideWindow(sender)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 || event.keyCode == 76,
            event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command {

            keyDownDelegate?.didCreateCombinationKeyDown(self)
        } else {
            super.keyDown(with: event)
        }
    }
}

extension NSTextView {
    var lineCount: Int {
        return string.components(separatedBy: .newlines).count
    }
}

protocol KeyDownDelegate: class {
    func didCreateCombinationKeyDown(_ textView: NSTextView)
}
