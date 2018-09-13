//
//  MainCollectionView.swift
//  LightMac
//
//  Created by hoemoon on 07/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import AppKit

protocol CollectionViewMenuDelegate: class {
    func removeNote(at index: Int)
}

class MainCollectionView: NSCollectionView {
    weak var menuDelegate: CollectionViewMenuDelegate!
    var indexPathForContextMenu: IndexPath?

    lazy var contextMenu: NSMenu = {
        let menu = NSMenu(title: "context menu")
        let item1 = NSMenuItem(title: "remove", action: #selector(removeNote), keyEquivalent: "")
        menu.addItem(item1)
        return menu
    }()

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if event.clickCount > 1 {

        }
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        let point = self.convert(event.locationInWindow, to: nil)
          indexPathForContextMenu = self.indexPathForItem(at: point)

        return contextMenu
    }

    @objc func removeNote() {
        if let indexPath = indexPathForContextMenu {
            menuDelegate.removeNote(at: indexPath.item)
            indexPathForContextMenu = nil
        }
    }
}
