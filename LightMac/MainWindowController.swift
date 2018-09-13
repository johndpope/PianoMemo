//
//  MainWindowController.swift
//  LightMac
//
//  Created by hoemoon on 06/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import AppKit

class MainWindowController: NSWindowController {
    private let inputTextViewHeight: CGFloat = 50
    private let maxCellCount: CGFloat = 9
    private let width: CGFloat = 550
    private let cellHeight: CGFloat = 50
    private var topLeftCorner: CGPoint!

    private var sizeForStartUp: NSSize {
        return NSSize(
            width: width,
            height: inputTextViewHeight
        )
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        guard let window = window, let screen = window.screen else { return }

        window.setContentSize(sizeForStartUp)
        let point = CGPoint(
            x: screen.frame.width / 2 - sizeForStartUp.width / 2,
            y: screen.frame.height / 2 - sizeForStartUp.height / 2 + maxCellCount / 2 * cellHeight
        )
        window.setFrame(CGRect(origin: point, size: sizeForStartUp), display: true)

        topLeftCorner = CGPoint(
            x: window.frame.origin.x, y: window.frame.origin.y + window.frame.height)

        if let mainViewController = contentViewController as? MainNSViewController {
            mainViewController.resizeDelegate = self
        }
    }
}

protocol WindowResizeDelegate: class {
    var heightOfRow: CGFloat { get }
    func setWindowHeight(with cellCount: Int)
}

extension MainWindowController: WindowResizeDelegate {
    var heightOfRow: CGFloat {
        return self.cellHeight
    }

    func setWindowHeight(with cellCount: Int) {
        let count = min(CGFloat(cellCount), maxCellCount)
        let newSize = NSSize(width: width,height: cellHeight * count + inputTextViewHeight)
        window?.setContentSize(newSize)
        window?.setFrameTopLeftPoint(topLeftCorner!)
    }
}
