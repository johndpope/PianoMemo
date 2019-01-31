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

//TODO: TextViewDidChange에서 데이터 소스에 저장 안했을 때 발생하는 문제가 있을까?
//엔드에디팅일 때 저장하면 되는 거 아닌가? 어차피 화면을 떠나든, 앱이 종료되든, endEditing이 호출되고 그다음 저장될 것이므로. -> 확인해보자.
//정규식을 활용해서

class BlockTableViewController: UITableViewController {

    internal var note: Note!
    internal var noteHandler: NoteHandlable!
    internal var imageHandler: ImageHandlable!
    internal var dataSource: [[String]] = []
    internal var baseString = ""
    weak var imageCache: NSCache<NSString, UIImage>?
    var timer: Timer!
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
                            self.noteHandler = appDelegate.noteHandler
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

        guard noteHandler != nil else { return }
        setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerAllNotifications()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setFirstCellBecomeResponderIfNeeded()
        unRegisterAllNotifications()
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
            vc.noteHandler = noteHandler
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
        if let imagePickerValue = PianoImageKey(type: .value(.imagePickerValue), text: str, selectedRange: range) {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ImagePickerTableViewCell.reuseIdentifier) as? ImagePickerTableViewCell else { return UITableViewCell() }
            
            return cell
            
        } else if let imageValue = PianoImageKey(type: .value(.imageValue), text: str, selectedRange: range) {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ImageBlockTableViewCell.reuseIdentifier) as? ImageBlockTableViewCell else { return UITableViewCell() }
            cell.imageValue = imageValue
            
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

    func resetTimer() {
        if timer != nil {
            timer.invalidate()
        }
        timer = Timer.scheduledTimer(
            timeInterval: 2.0,
            target: self,
            selector: #selector(saveNoteIfNeeded),
            userInfo: nil,
            repeats: false
        )
    }
}

extension BlockTableViewController: ImageInputViewDelegate {
    func handle(selected asset: PHAsset) {
//        guard let editing = editingCell, let currentPath = editingIndexPath else { return }
//        let nextPath = IndexPath(row: currentPath.row + 1, section: currentPath.section)
//        let nextCell = tableView.cellForRow(at: nextPath) as? BlockTableViewCell
//        let isCurrentTextEmpty = editing.textView.text.isEmpty
//
//        editing.textView.inputView = nil
//        editing.textView.reloadInputViews()
//
//        switch nextCell {
//        case .some(let next):
//            if isCurrentTextEmpty {
//                insertImageCell(at: currentPath, with: asset)
//                next.textView.becomeFirstResponder()
//                next.textView.invalidateCaretPosition()
//            } else {
//                insertImageCell(at: nextPath, with: asset)
//                next.textView.becomeFirstResponder()
//                next.textView.invalidateCaretPosition()
//            }
//        case .none:
//            if isCurrentTextEmpty {
//                insertImageCell(at: currentPath, with: asset)
//            } else {
//                insertImageCell(at: nextPath, with: asset)
//                insertEmptyCell(at: IndexPath(row: nextPath.row + 1, section: nextPath.section))
//            }
//        }
    }

    private func insertImageCell(at path: IndexPath, with asset: PHAsset) {
//        self.dataSource[path.section].insert("", at: path.row)
//        self.tableView.insertRows(at: [path], with: .none)
//        let insertedCell = self.tableView.cellForRow(at: path) as? BlockTableViewCell
//        insertedCell?.activityIndicatorView.startAnimating()
//
//        PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: nil) { [weak self] image, _ in
//            guard let self = self, let image = image else { return }
//            self.imageHandler.saveImage(image) { imageID in
//                DispatchQueue.main.async { [weak self] in
//                    guard let self = self, let id = imageID?.encodedImageID else { return }
//                    self.dataSource[path.section][path.row] = id
//                    insertedCell?.loadImage()
//                }
//            }
//        }
    }

    private func insertEmptyCell(at path: IndexPath) {
//        self.dataSource[path.section].insert("", at: path.row)
//        self.tableView.insertRows(at: [path], with: .none)
//        let cell = tableView.cellForRow(at: path) as? BlockTableViewCell
//        cell?.textView.becomeFirstResponder()
//        cell?.textView.invalidateCaretPosition()
    }
}
