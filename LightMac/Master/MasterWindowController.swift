//
//  MasterWindowController.swift
//  LightMac
//
//  Created by hoemoon on 06/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import AppKit

class MasterWindowController: NSWindowController {
    struct Constants {
        static let margin: CGFloat = 5
        static let cellHeight: CGFloat = Preference.defaultFont.pointSize
            + margin * 2
        static let maxCellCount: CGFloat = 9
        static let maxWidth: CGFloat = 700
    }

    private var inputViewHeight: CGFloat {
        let layoutManager = NSLayoutManager()
        return layoutManager.defaultLineHeight(for: Preference.defaultFont)
            + Constants.margin * 2
    }

    private var topLeftCorner: CGPoint!

    private var sizeForStartUp: NSSize {
        return NSSize(
            width: Constants.maxWidth,
            height: inputViewHeight
        )
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        guard let window = window, let screen = window.screen else { return }

        window.setContentSize(sizeForStartUp)
        let point = CGPoint(
            x: screen.frame.width / 2 - sizeForStartUp.width / 2,
            y: screen.frame.height / 2 - sizeForStartUp.height / 2
                + Constants.maxCellCount / 2 * Constants.cellHeight
        )
        window.setFrame(CGRect(origin: point, size: sizeForStartUp), display: true)

        topLeftCorner = CGPoint(
            x: window.frame.origin.x, y: window.frame.origin.y + window.frame.height)

        if let mainViewController = contentViewController as? MasterViewController {
            mainViewController.resizeDelegate = self
        }
    }
}

protocol WindowResizeDelegate: class {
    func setWindowHeight(with height: CGFloat)
}

extension MasterWindowController: WindowResizeDelegate {
    func setWindowHeight(with height: CGFloat) {
        guard let point = topLeftCorner else { return }
        let newSize = NSSize(
            width: Constants.maxWidth,
            height: height
        )
        window?.setContentSize(newSize)
        window?.setFrameTopLeftPoint(point)
    }
}
