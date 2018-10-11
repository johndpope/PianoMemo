//
//  MasterViewController.swift
//  LightMac
//
//  Created by hoemoon on 10/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Cocoa

class MasterViewController: NSViewController {
    @IBOutlet weak var inputTextView: InputTextView!
    @IBOutlet weak var resultsTableView: NSTableView!
    @IBOutlet weak var previewTextView: NSTextView!

    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!

    @objc let backgroundContext: NSManagedObjectContext
    weak var resizeDelegate: WindowResizeDelegate?

    private var floatedNotes = Set<NSManagedObjectID>()
    private(set) var state: State = .ready

    enum State {
        case ready
        case search
        case create
    }

    required init?(coder: NSCoder) {
        guard let delegate = NSApplication.shared.delegate as? AppDelegate else {
            fatalError()
        }
        backgroundContext = delegate.persistentContainer.newBackgroundContext()
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        inputTextView.font = LocalPreference.defaultFont
        inputTextView.delegate = self
        inputTextView.keyDownDelegate = self
        resultsTableView.delegate = self
        arrayController.sortDescriptors = [
            NSSortDescriptor(key: "modifiedAt", ascending: false)
        ]
        tableViewHeightConstraint.constant = 0
//        setupDummy()
        resultsTableView.doubleAction = #selector(didDoubleClick(_:))
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        if inputTextView.acceptsFirstResponder {
            inputTextView.window?.makeFirstResponder(inputTextView)
        }
    }
}

extension MasterViewController {
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
        let randomStrings: String =
            "Donec sed odio dui. Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor.",
            "Aenean lacinia bibendum nulla sed consectetur. Nulla vitae elit libero, a pharetra augue.",
            "Cras justo odio, dapibus ac facilisis in, egestas eget quam. Donec ullamcorper nulla non metus auctor fringilla.",
            "Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus.",
            "Etiam porta sem malesuada magna mollis euismod. Nullam quis risus eget urna mollis ornare vel eu leo."
        
        for index in 1...1000000 {
            let note = Note(context: backgroundContext)
            let number = arc4random_uniform(UInt32(randomStrings.count))
            note.modifiedAt = Date()
            note.createdAt = Date()
            note.content = "\(index) \(number) \(randomStrings[Int(number)])"
        }
        saveIfneeded()
    }

    private func updateWindowHeight() {
        var sum: CGFloat = 0
        sum += arrayController.heightForTableView
        sum += inputTextView.calculatedHeight
        resizeDelegate?.setWindowHeight(with: sum)
    }

    private func selectFirstRow() {
        if resultsTableView.numberOfRows > 0 {
            resultsTableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
    }

    private func updateOutputTableViewHeight() {
        tableViewHeightConstraint.constant = arrayController.heightForTableView
    }

    private func updateState() {
        if arrayController.notes.count > 0 {
            state = .search
        } else if inputTextView.lineCount > 1 {
            state = .create
        } else {
            state = .ready
        }
    }

    private func createNote(_ text: String) {
        let note = Note(context: backgroundContext)
        note.content = text
        note.createdAt = Date()
        note.modifiedAt = Date()

        arrayController.addObject(note)

        saveIfneeded { [weak self] in
            self?.inputTextView.string = ""
            self?.arrayController.filterPredicate = NSPredicate(value: false)
            // TODO: 작은 팝업으로 생성을 알려주면 좋을 듯
            self?.updateOutputTableViewHeight()
            self?.updateWindowHeight()
        }
    }

    @objc private func didDoubleClick(_ sender: Any?) {
        guard let tableView = sender as? NSTableView,
            !floatedNotes.contains(arrayController.noteID(with: tableView.selectedRow)) else { return }
        showDetail()
    }

    private func showDetail() {
        let id = "DetailWindowController"
        guard let storyboard = storyboard,
            let detailWindowController = storyboard.instantiateController(withIdentifier: id)
                as? DetailWindowController,
            let viewController = detailWindowController.contentViewController
                as? DetailViewController else { return }

        let note = arrayController.notes[resultsTableView.selectedRow]
        viewController.note = note
        viewController.postActionDelegate = self

        detailWindowController.showWindow(nil)

        floatedNotes.insert(note.objectID)
    }
}

extension MasterViewController: NSTextViewDelegate, KeyDownDelegate {
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? InputTextView else { return }

        let isValidInput = textView.string.count > 0 &&
            textView.lineCount == 1

        let predicate = isValidInput ?
            textView.string.predicate(fieldName: "Content") :
            NSPredicate(value: false)

        arrayController.filterPredicate = predicate
        updateOutputTableViewHeight()
        updateWindowHeight()
        selectFirstRow()
        updateState()
    }

    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard resultsTableView.numberOfRows != 0 else { return false }
        let currentIndex = resultsTableView.selectedRow

        switch commandSelector {
        case #selector(NSResponder.moveUp(_:)):
            resultsTableView.selectRowIndexes(IndexSet(integer: currentIndex - 1), byExtendingSelection: false)
            return true
        case #selector(NSResponder.moveDown(_:)):
            resultsTableView.selectRowIndexes(IndexSet(integer: currentIndex + 1), byExtendingSelection: false)
            return true
        case #selector(NSResponder.insertNewline(_:)):
            showDetail()
            return true
        default:
            return false
        }
    }

    func didCreateCombinationKeyDown(_ textView: NSTextView) {
        createNote(textView.string)
    }

    func didTapEscapeKeyOnSearch() {
        inputTextView.string = ""
        arrayController.filterPredicate = NSPredicate(value: false)
        updateOutputTableViewHeight()
        updateWindowHeight()
        selectFirstRow()
    }

}

extension MasterViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return MasterWindowController.Constants.cellHeight
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else { return }
        tableView.scrollRowToVisible(tableView.selectedRow)
    }
}

extension MasterViewController: DetailPostActionDelegate {
    func didCloseDetailViewController(that note: Note) {
        floatedNotes.remove(note.objectID)
    }
}

private extension NSArrayController {
    func noteID(with index: Int) -> NSManagedObjectID {
        return notes[index].objectID
    }
    var notes: [Note] {
        if let notes = arrangedObjects as? [Note] {
            return notes
        } else {
            return []
        }
    }

    var heightForTableView: CGFloat {
        let count = min(
            CGFloat(notes.count),
            MasterWindowController.Constants.maxCellCount
        )
        return count
            * MasterWindowController.Constants.cellHeight
    }
}


