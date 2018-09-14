//
//  InputTextView.swift
//  LightMac
//
//  Created by hoemoon on 11/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import AppKit

class InputTextView: NSTextView {
    weak var keyDownDelegate: KeyDownDelegate?

    var calculatedHeight: CGFloat {
        guard let container = textContainer,
            let layoutManager = layoutManager,
            let font = font else { return 0 }
        let maxHeight = layoutManager.defaultLineHeight(for: font) * 10
        return min(layoutManager.usedRect(for: container).height, maxHeight)
            + 10 // for margin
    }

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
