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
    private var isMouseDowned = false

    var calculatedHeight: CGFloat {
        guard let container = textContainer,
            let layoutManager = layoutManager,
            let font = font else { return 0 }
        let maxHeight = layoutManager.defaultLineHeight(for: font) * 10
        return min(layoutManager.usedRect(for: container).height, maxHeight)
            + 10 // for margin
    }

    override func cancelOperation(_ sender: Any?) {
        guard let delegate = keyDownDelegate else { return }
        switch delegate.state {
        case .ready:
            hideWindow()
        case .search:
            delegate.didTapEscapeKeyOnSearch()
        case .create:
            hideWindow()
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 || event.keyCode == 76,
            event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command {

            keyDownDelegate?.didCreateCombinationKeyDown(self)
        } else {
            super.keyDown(with: event)
        }
    }

    override var mouseDownCanMoveWindow: Bool {
        return true
    }

    private func hideWindow() {
        (NSApplication.shared.delegate as? AppDelegate)?.hideWindow(nil)
    }
}

extension NSTextView {
    var lineCount: Int {
        return string.components(separatedBy: .newlines).count
    }
}

protocol KeyDownDelegate: class {
    var state: MasterViewController.State { get }
    func didCreateCombinationKeyDown(_ textView: NSTextView)
    func didTapEscapeKeyOnSearch()
}
