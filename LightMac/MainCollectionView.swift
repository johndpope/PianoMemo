//
//  MainCollectionView.swift
//  LightMac
//
//  Created by hoemoon on 07/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import AppKit

class MainCollectionView: NSCollectionView {
    override func rightMouseDown(with event: NSEvent) {
        super.rightMouseDown(with: event)

    }

    override func menu(for event: NSEvent) -> NSMenu? {
        let point = self.convert(event.locationInWindow, to: nil)
        let item = self.indexPathForItem(at: point)

        let menu = NSMenu(title: "first menu")
        let menuItem1 = NSMenuItem(title: "first tiem", action: nil, keyEquivalent: "key")
        let menuItem2 = NSMenuItem(title: "second tiem", action: nil, keyEquivalent: "key")
        menu.addItem(menuItem1)
        menu.addItem(menuItem2)
        return menu
    }
}
