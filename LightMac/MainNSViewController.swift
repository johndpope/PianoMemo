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
        textView.font = Preference.defaultFont
        textView.delegate = self
        textView.keyDownDelegate = self
        tableView.delegate = self
        arrayController.sortDescriptors = [
            NSSortDescriptor(key: "modifiedDate", ascending: false)
        ]
        textViewHeightConstraint.constant = 50 + 7
//        setupDummy()
    }

}

extension MainNSViewController {
    func saveIfneeded(_ completionHandler: (() -> Void)? = nil) {
        if !backgroundContext.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if backgroundContext.hasChanges {
            do {
                try backgroundContext.save()
                completionHandler?()
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
        saveIfneeded()
    }

    private func updateWindowHeight() {
        if let objects = arrayController.arrangedObjects as? [Note] {
            let count = objects.count
            resizeDelegate?.setWindowHeight(with: count)
        }
    }

    private func createNote(_ text: String) {
        let note = Note(context: backgroundContext)
        note.content = text
        note.createdDate = Date()
        note.modifiedDate = Date()

        arrayController.addObject(note)

        saveIfneeded { [weak self] in
            self?.textView.string = ""
            self?.arrayController.filterPredicate = NSPredicate(value: false)
            // TODO: 작은 팝업으로 생성을 알려주면 좋을 듯
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

        if (arrayController.arrangedObjects as! [Note]).count == 0 {
            let height = textView.calculatedHeight + 10
            textViewHeightConstraint.constant = height
            resizeDelegate?.setWindowHeight(with: height)
        } else {
            updateWindowHeight()
        }
    }

    func didCreateCombinationKeyDown(_ textView: NSTextView) {
        createNote(textView.string)
    }

//    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
//        // TODO: 커서가 제일 마지막 줄에 있으면 밑의 셀을 선택할 수 있는 걸로 개선해야 함.
//        guard textView.lineCount == 1 else { return false }
//        switch commandSelector {
//        case #selector(NSResponder.moveUp(_:)):
//            print("upup")
//            return true
//        case #selector(NSResponder.moveDown(_:)):
//            print("down")
//            return true
//        default:
//            return false
//        }
//    }
}

extension MainNSViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return resizeDelegate?.heightForRow ?? 0
    }
}
