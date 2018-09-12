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

    private var defaultSize: NSSize {
        return NSSize(
            width: width,
            height: maxCellCount * cellHeight + inputTextViewHeight
        )
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        guard let window = window else { return }
        window.setContentSize(defaultSize)
        window.center()

        topLeftCorner = CGPoint(
            x: window.frame.origin.x, y: window.frame.origin.y + window.frame.height)
        if let mainViewController = contentViewController as? MainNSViewController {
            mainViewController.delegate = self
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
        print(topLeftCorner.y, "topLeft")
        window?.setContentSize(newSize)
        window?.setFrameTopLeftPoint(topLeftCorner!)
    }
}
