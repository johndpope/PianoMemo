//
//  MainWindowController.swift
//  LightMac
//
//  Created by hoemoon on 06/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import AppKit

class MainWindowController: NSWindowController {
    // static value
    private let maxCellCount: CGFloat = 9
    private let maxWidth: CGFloat = 550
    private let margin: CGFloat = 5

    private var textViewWrapperHeight: CGFloat {
        return Preference.defaultFont.pointSize + margin * 2
            + 7
    }
    private var cellHeight: CGFloat {
        return Preference.defaultFont.pointSize + margin * 2
    }
    private var maxHeight: CGFloat {
        return cellHeight * maxCellCount
    }
    private var topLeftCorner: CGPoint!

    private var sizeForStartUp: NSSize {
        return NSSize(
            width: maxWidth,
            height: textViewWrapperHeight
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
    var heightForRow: CGFloat { get }
    func setWindowHeight(with cellCount: Int)
    func setWindowHeight(with additionalHeight: CGFloat)
}

extension MainWindowController: WindowResizeDelegate {
    var heightForRow: CGFloat {
        return self.cellHeight
    }

    func setWindowHeight(with cellCount: Int) {
        let count = min(CGFloat(cellCount), maxCellCount)
        let newSize = NSSize(
            width: maxWidth,
            height: cellHeight * count + textViewWrapperHeight
        )
        window?.setContentSize(newSize)
        window?.setFrameTopLeftPoint(topLeftCorner!)
    }

    func setWindowHeight(with additionalHeight: CGFloat) {
        if additionalHeight < maxHeight {
            let newSize = NSSize(
                width: maxWidth,
                height: additionalHeight
            )
            window?.setContentSize(newSize)
            window?.setFrameTopLeftPoint(topLeftCorner!)
        }
    }
}
