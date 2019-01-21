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

//    override func mouseDown(with event: NSEvent) {
//        super.mouseDown(with: event)
//        print(event.locationInWindow)
//        isMouseDowned = true
//    }
//
//    override func mouseUp(with event: NSEvent) {
//        super.mouseUp(with: event)
//        isMouseDowned = false
//    }
//
//    override func mouseMoved(with event: NSEvent) {
//        super.mouseMoved(with: event)
//        guard let window = window, isMouseDowned else { return }
////        print(event.locationInWindow)
////        if let window = window {
////            let old = window.frame.origin
////            window.setFrameOrigin(<#T##point: NSPoint##NSPoint#>)
////        }
//    }
//
//    override func touchesBegan(with event: NSEvent) {
//        super.touchesBegan(with: event)
//
//    }
//    override func mouseDragged(with event: NSEvent) {
//        super.mouseDragged(with: event)
//    }
//
//    override func mouseEntered(with event: NSEvent) {
//        super.mouseEntered(with: event)
//    }

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
