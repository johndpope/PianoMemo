//
//  BlockTableViewController.swift
//  Piano
//
//  Created by Kevin Kim on 16/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit
import EventKit
import Photos

class BlockTableViewController: UITableViewController, UITableViewDataSourcePrefetching {

    internal var note: Note!
    internal var dataSource: [[String]] = []
    internal var baseString = ""
    internal var blockTableState: BlockTableState = .normal(.read) {
        didSet {
            //4개의 세팅
            setupNavigationBar()
            setupToolbar()
            setupPianoViewIfNeeded()
        }
    }

    override func encodeRestorableState(with coder: NSCoder) {
        guard let note = note else { return }
        coder.encode(note.objectID.uriRepresentation(), forKey: "noteURI")
        super.encodeRestorableState(with: coder)
    }

    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        if let url = coder.decodeObject(forKey: "noteURI") as? URL {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.decodeNote(url: url) { note in
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        switch note {
                        case .some(let note):
                            self.note = note
                            self.setup()
                        case .none:
                            self.popCurrentViewController()
                        }
                    }
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        registerAllNotifications()
        setup()
    }

    deinit {
        unRegisterAllNotifications()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setFirstCellBecomeResponderIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
        saveNoteIfNeeded(needToSave: true)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        guard blockTableState == .normal(.editing) || blockTableState == .normal(.read) else { return }
        blockTableState = editing ? .normal(.editing) : .normal(.read)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? NoteInfoCollectionViewController {
            vc.note = note
            return
        }

        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? NoteSharingCollectionViewController {
            vc.note = note
            vc.blockTableVC = self
            return
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let str = dataSource[indexPath.section][indexPath.row]

        let range = NSRange(location: 0, length: 0)
        if let _ = PianoAssetKey(type: .value(.imagePickerValue), text: str, selectedRange: range) {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ImagePickerTableViewCell.reuseIdentifier) as? ImagePickerTableViewCell else { return UITableViewCell() }
            cell.blockTableViewVC = self

            return cell

        } else if let imageValue = PianoAssetKey(type: .value(.imageValue), text: str, selectedRange: range) {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ImagesBlockTableViewCell.reuseIdentifier) as? ImagesBlockTableViewCell else { return UITableViewCell() }
            cell.blockTableViewVC = self

            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TextBlockTableViewCell.reuseIdentifier) as? TextBlockTableViewCell else { return UITableViewCell() }
            configure(cell: cell, indexPath: indexPath)
            return cell
        }

    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let count = dataSource[indexPath.section][indexPath.row].trimmingCharacters(in: .whitespacesAndNewlines).count
        return count != 0 ? UITableViewCell.EditingStyle(rawValue: 3) ?? .none : .none
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let count = dataSource[indexPath.section][indexPath.row].trimmingCharacters(in: .whitespacesAndNewlines).count
        if count == 0 { return false }
        if blockTableState == .normal(.piano) { return false }
        if blockTableState == .normal(.editing) { return true }
        if blockTableState == .normal(.read) { return true }
        if blockTableState == .normal(.typing) { return true }
        if tableView.isEditing { return false }
        return true
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        guard let cell = tableView.cellForRow(at: indexPath) as? TextBlockTableViewCell else { return false }
        return cell.textView.text.trimmingCharacters(in: .whitespacesAndNewlines).count != 0
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        setToolbarBtnsEnabled()
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        setToolbarBtnsEnabled()
    }

    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        let str = dataSource[indexPath.section][indexPath.row]
        guard canSwipe(str: str) else { return nil }

        let eventStore = EKEventStore()
        let selectedRange = NSRange(location: 0, length: 0)
        if let headerKey = HeaderKey(text: str, selectedRange: selectedRange) {
            return UISwipeActionsConfiguration(
                actions: [resetAction(str, headerKey, indexPath)])
        } else if let reminder = str.reminderKey(store: eventStore) {
            return UISwipeActionsConfiguration(
                actions: [reminderAction(reminder, eventStore)])
        } else if PianoBullet(type: .key, text: str, selectedRange: NSRange(location: 0, length: 0)) == nil {
            return UISwipeActionsConfiguration(
                actions: [titleAction(str, indexPath)])
        } else {
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        let str = dataSource[indexPath.section][indexPath.row]
        guard canSwipe(str: str) else { return nil }

        return UISwipeActionsConfiguration(
            actions: [deleteAction(indexPath),
                      copyAction(str) ])
    }

    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        ()
    }
}
