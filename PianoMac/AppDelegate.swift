//
//  AppDelegate.swift
//  LightMac
//
//  Created by hoemoon on 05/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Cocoa
import MASShortcut

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    lazy var statusMenu: NSMenu = {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show", action: #selector(showWindow(_:)), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }()
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    var mouseEventMonitor: MouseEventMonitor?

    var mainWindow: MasterWindow?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem.menu = statusMenu
        if let button = statusItem.button {
            button.image = NSImage(named: "StatusBarButtonImage")
        }

        mainWindow = NSApplication.shared.windows
            .compactMap { $0 as? MasterWindow }.first

//        setupMouseEventMonitor()
        showWindow(nil)
        registerGlobalShortcut()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Light")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(_ sender: AnyObject?) {
        let context = persistentContainer.viewContext

        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }

    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        return persistentContainer.viewContext.undoManager
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let context = persistentContainer.viewContext

        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }

        if !context.hasChanges {
            return .terminateNow
        }

        do {
            try context.save()
        } catch {
            let nserror = error as NSError

            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if result {
                return .terminateCancel
            }

            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info")
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)

            let answer = alert.runModal()
            if answer == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }

}

extension AppDelegate {
    @objc func showWindow(_ sender: Any?) {
//        mainWindow?.level = .modalPanel
        mainWindow?.makeKeyAndOrderFront(sender)
        NSApp.activate(ignoringOtherApps: true)
//        mainWindow?.orderFrontRegardless()
        mouseEventMonitor?.start()
    }

    func hideWindow(_ sender: Any?) {
        mouseEventMonitor?.stop()
        mainWindow?.orderOut(nil)
    }

    func setupMouseEventMonitor() {
        mouseEventMonitor = MouseEventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let `self` = self else { return }
            self.hideWindow(nil)
        }
    }

    func registerGlobalShortcut() {
        let flags = [NSEvent.ModifierFlags.command, NSEvent.ModifierFlags.option].map { $0.rawValue }.reduce(0, +)

        let shortcut = MASShortcut(keyCode: UInt(kVK_Space), modifierFlags: UInt(flags))

        MASShortcutMonitor.shared()?.register(shortcut, withAction: { [weak self] in
            self?.showWindow(nil)
        })
    }
}
