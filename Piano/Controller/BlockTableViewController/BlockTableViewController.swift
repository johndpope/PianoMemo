//
//  BlockTableViewController.swift
//  Piano
//
//  Created by Kevin Kim on 16/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit
import EventKit

//TODO: TextViewDidChange에서 데이터 소스에 저장 안했을 때 발생하는 문제가 있을까?
//엔드에디팅일 때 저장하면 되는 거 아닌가? 어차피 화면을 떠나든, 앱이 종료되든, endEditing이 호출되고 그다음 저장될 것이므로. -> 확인해보자.
//정규식을 활용해서

class BlockTableViewController: UITableViewController {
    @IBOutlet weak var inputHelperView: UIView!

    @IBOutlet weak var imageInputView: ImageInputView!
    internal var note: Note!
    internal var noteHandler: NoteHandlable!
    internal var dataSource: [[String]] = []
    internal var hasEdit = false
    private var baseString = ""
    internal var editingTextView: BlockTextView?
    internal var blockTableState: BlockTableState = .normal(.read) {
        didSet {
            //4개의 세팅
            setupNavigationBar()
            setupToolbar()
            setupPianoViewIfNeeded()
            Feedback.success()
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

    @IBAction func didTapImageButton(_ sender: Any) {
        guard let textView = editingTextView else { return }
        switch textView.inputView {
        case .some:
            textView.inputView = nil
        case .none:
            imageInputView.setup()
            textView.inputView = imageInputView
        }
        textView.reloadInputViews()
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
        saveNoteIfNeeded()
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        guard blockTableState == .normal(.editing) || blockTableState == .normal(.read) else { return }
        blockTableState = editing ? .normal(.editing) : .normal(.read)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BlockTableViewCell.reuseIdentifier) as! BlockTableViewCell
        configure(cell: cell, indexPath: indexPath)
        return cell
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let count = dataSource[indexPath.section][indexPath.row].trimmingCharacters(in: .whitespacesAndNewlines).count
        return count != 0 ? UITableViewCell.EditingStyle(rawValue: 3) ?? .none : .none
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let count = dataSource[indexPath.section][indexPath.row].trimmingCharacters(in: .whitespacesAndNewlines).count
        if count == 0 { return false }

        if blockTableState == .normal(.typing) || blockTableState == .normal(.read) {
            return true
        } else {
            return false
        }
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        guard let cell = tableView.cellForRow(at: indexPath) as? BlockTableViewCell else { return false }
        return cell.textView.text.trimmingCharacters(in: .whitespacesAndNewlines).count != 0
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        setToolbarBtnsEnabled()
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        setToolbarBtnsEnabled()
    }

//    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//
//        let str = dataSource[indexPath.section][indexPath.row]
//        
//        //1. 텍스트가 없거나, editing 중이라면, 스와이프 할 수 없게 만들기
//        guard str.trimmingCharacters(in: .whitespacesAndNewlines).count != 0
//            && !tableView.isEditing else { return nil }
//
//        let eventStore = EKEventStore()
//        let selectedRange = NSRange(location: 0, length: 0)
//        if let headerKey = HeaderKey(text: str, selectedRange: selectedRange) {
//            //2. 헤더키가 존재한다면, 본문으로 돌리는 버튼만 노출시키고, 누르면 데이터 소스에서 지우고, 리로드하기
//            let resetAction = UIContextualAction(style: .normal, title: nil) { [weak self](_, _, success) in
//                guard let self = self else { return }
//                let trimStr = (str as NSString).replacingCharacters(in: headerKey.rangeToRemove, with: "")
//                self.dataSource[indexPath.section][indexPath.row] = trimStr
//                self.tableView.reloadRows(at: [indexPath], with: .automatic)
//                self.hasEdit = true
//                success(true)
//            }
//            resetAction.image = #imageLiteral(resourceName: "resetH")
//            resetAction.backgroundColor = Color(red: 185/255, green: 188/255, blue: 191/255, alpha: 1)
//            return UISwipeActionsConfiguration(actions: [resetAction])
//        } else if let reminder = str.reminderKey(store: eventStore) {
//            var contextualActions: [UIContextualAction] = []
//            let reminderAction = UIContextualAction(style: .normal, title: nil) { [weak self](_, _, success) in
//                guard let self = self, let vc = self.
//            }
//        }
//    }

}

extension BlockTableViewController {
    private func setup() {
        blockTableState = .normal(.read)
        setupForMerge()
        setupForDataSource()
        setBackgroundViewForTouchEvent()
    }

    internal func saveNoteIfNeeded() {
        //TextViewDelegate의 endEditing을 통해 저장을 유도
        view.endEditing(true)

        guard let note = note,
            let strArray = dataSource.first,
            hasEdit else {return }

        let content = strArray.joined(separator: "\n")
        noteHandler.update(origin: note, content: content)
        hasEdit = false
    }

    private func configure(cell: BlockTableViewCell, indexPath: IndexPath) {
        cell.blockTableVC = self
        cell.textView.blockTableVC = self
        cell.textView.inputAccessoryView = inputHelperView
        cell.data = dataSource[indexPath.section][indexPath.row]
        cell.setupForPianoIfNeeded()
    }

    private func setupForDataSource() {
        guard let note = note,
            let content = note.content else { return }

        //reset
        dataSource = []

        //set
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let contents = content.components(separatedBy: .newlines)
            self.dataSource.append(contents)
            DispatchQueue.main.async {
                self.tableView.reloadData()
                Analytics.logEvent(viewNote: note)
            }
        }
    }

    //새 메모 쓰거나 아예 메모가 없을 경우 키보드를 띄워준다.
    internal func setFirstCellBecomeResponderIfNeeded() {
        let indexPath = IndexPath(row: 0, section: 0)
        guard let cell = tableView.cellForRow(at: indexPath) as? BlockCell,
            tableView.numberOfRows(inSection: 0) == 1,
            cell.textView.text.count == 0 else { return }
        if !cell.textView.isFirstResponder {
            cell.textView.becomeFirstResponder()
            hasEdit = true
        }
    }

    private func setBackgroundViewForTouchEvent() {

        let view = UIView()
        view.backgroundColor = .clear
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapBackground(_:)))
        view.addGestureRecognizer(tapGestureRecognizer)
        self.tableView.backgroundView = view
    }

    @IBAction func tapBackground(_ sender: UITapGestureRecognizer) {
        //TODO: 이부분 제대로 동작하는 지 체크(제대로 동작한다면, enum에 단순히 Equatable만 적어주면 된다.
        guard blockTableState == .normal(.typing)
            || blockTableState == .normal(.read) else { return }

        let point = sender.location(in: self.tableView)
        if let indexPath = tableView.indexPathForRow(at: point),
            let cell = tableView.cellForRow(at: indexPath) as? BlockCell {
            if point.x < self.tableView.center.x {
                //앞쪽에 배치
                cell.textView.selectedRange = NSRange(location: 0, length: 0)
                if !cell.textView.isFirstResponder {
                    cell.textView.becomeFirstResponder()
                }
            } else {
                //뒤쪽에 배치
                cell.textView.selectedRange = NSRange(location: cell.textView.attributedText.length, length: 0)
                if !cell.textView.isFirstResponder {
                    cell.textView.becomeFirstResponder()
                }
            }
        } else {
            //마지막 셀이 존재한다면(없다면 생성하기), 마지막 셀의 마지막 부분에 커서를 띄운다.
            if let count = dataSource.first?.count,
                count != 0,
                dataSource.count != 0 {
                let row = count - 1
                let indexPath = IndexPath(row: row, section: dataSource.count - 1)
                guard let cell = tableView.cellForRow(at: indexPath) as? BlockCell else { return }
                cell.textView.selectedRange = NSRange(location: cell.textView.attributedText.length, length: 0)
                if !cell.textView.isFirstResponder {
                    cell.textView.becomeFirstResponder()
                }
            }
        }
    }

//    private func detectTapBackground

    private func setupForMerge() {
        if let note = note, let content = note.content {
            self.baseString = content
            EditingTracker.shared.setEditingNote(note: note)
        }
    }

    internal func registerAllNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(merge(_:)),
            name: .resolveContent,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(popCurrentViewController),
            name: .popDetail,
            object: nil
        )
    }

    @objc func popCurrentViewController() {
        DispatchQueue.main.async {
            [weak self] in
            guard let self = self else { return }
            self.navigationController?.popViewController(animated: true)
        }
    }

    @objc private func merge(_ notification: Notification) {
//        DispatchQueue.main.sync {
//            guard let their = note?.content,
//                let first = pianoEditorView.dataSource.first else { return }
//
//            let mine = first.joined(separator: "\n")
//            guard mine != their else {
//                baseString = mine
//                return
//            }
//            let resolved = Resolver.merge(
//                base: baseString,
//                mine: mine,
//                their: their
//            )
//
//            let newComponents = resolved.components(separatedBy: .newlines)
//            pianoEditorView.dataSource = []
//            pianoEditorView.dataSource.append(newComponents)
//            pianoEditorView.tableView.reloadData()
//
//            baseString = resolved
//        }
    }

    internal func unRegisterAllNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    internal func setupPianoViewIfNeeded() {
        switch blockTableState {
        case .normal(let detailState):
            switch detailState {
            case .piano:
                guard let navView = navigationController?.view, let pianoView = navView.createSubviewIfNeeded(PianoView.self) else { return }
                pianoView.attach(on: navView)
            default:
                ()
            }
        default:
            ()
        }
        tableView.visibleCells.forEach {
            ($0 as? BlockCell)?.setupForPianoIfNeeded()
        }
    }
}
