//
//  MainWindowController.swift
//  LightMac
//
//  Created by hoemoon on 06/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import AppKit

class MainWindowController: NSWindowController {
    var managedContext: NSManagedObjectContext!
    override func windowWillLoad() {
        managedContext = (NSApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

        super.windowWillLoad()
    }

    override func windowDidLoad() {
        super.windowDidLoad()
    }
}
