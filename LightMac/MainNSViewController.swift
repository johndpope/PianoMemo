//
//  MainNSViewController.swift
//  LightMac
//
//  Created by hoemoon on 10/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Cocoa

class MainNSViewController: NSViewController {
    @IBOutlet weak var textView: TextView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!

    @objc let backgroundContext: NSManagedObjectContext
    weak var resizeDelegate: WindowResizeDelegate?

    required init?(coder: NSCoder) {
        guard let delegate = NSApplication.shared.delegate as? AppDelegate else {
            fatalError()
        }
        backgroundContext = delegate.persistentContainer.newBackgroundContext()
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.font = NSFont.systemFont(ofSize: 15)
        textView.delegate = self
        textView.keyDownDelegate = self
        tableView.delegate = self
        arrayController.sortDescriptors = [
            NSSortDescriptor(key: "modifiedDate", ascending: false)
        ]
//        setupDummy()
    }
}

extension MainNSViewController {
    func saveIfneed() {
        if !backgroundContext.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if backgroundContext.hasChanges {
            do {
                try backgroundContext.save()
            } catch {
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }

    private func setupDummy() {
        let randomStrings: [String] = [
            "Donec sed odio dui. Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor.",
            "Aenean lacinia bibendum nulla sed consectetur. Nulla vitae elit libero, a pharetra augue.",
            "Cras justo odio, dapibus ac facilisis in, egestas eget quam. Donec ullamcorper nulla non metus auctor fringilla.",
            "Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus.",
            "Etiam porta sem malesuada magna mollis euismod. Nullam quis risus eget urna mollis ornare vel eu leo."
        ]
        for index in 1...100 {
            let note = Note(context: backgroundContext)
            let number = arc4random_uniform(UInt32(randomStrings.count))
            note.modifiedDate = Date()
            note.createdDate = Date()
            note.content = "\(index) \(number) \(randomStrings[Int(number)])"
        }
        saveIfneed()
    }

    private func updateWindowHeight() {
        if let objects = arrayController.arrangedObjects as? [Note] {
            let count = objects.count
            resizeDelegate?.setWindowHeight(with: count)
        }
    }
}

extension MainNSViewController: NSTextViewDelegate, KeyDownDelegate {
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? TextView else { return }

        let predicate = textView.string.count > 0 ?
            textView.string.predicate(fieldName: "Content") :
            NSPredicate(value: false)

        arrayController.filterPredicate = predicate
        updateWindowHeight()
    }

    func didCreateCombinationKeyDown() {

    }

    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard textView.lineCount == 1 else { return false }
        switch commandSelector {
        case #selector(NSResponder.moveUp(_:)):
            print("upup")
            return true
        case #selector(NSResponder.moveDown(_:)):
            print("down")
            return true
        default:
            return false
        }
    }
}

extension MainNSViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return resizeDelegate?.heightOfRow ?? 0
    }
}
