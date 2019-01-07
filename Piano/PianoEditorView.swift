//
//  PianoEditorView.swift
//  Piano
//
//  Created by Kevin Kim on 11/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import CoreData
import EventKitUI

class PianoEditorView: UIView, TableRegisterable {
    enum TableViewState {
        case normal
        case editing
        case typing
        case piano
        case trash
        case readOnly
    }

    weak var viewController: UIViewController?
//    private var kbHeight: CGFloat = 0
    private lazy var tableViewBottomMargin: CGFloat = {
       return bottomMarginOrigin
    }()
    @IBOutlet weak var detailToolbar: DetailToolbar!
    @IBOutlet weak var tapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var tableView: UITableView!
    internal var state: TableViewState = .normal {
        didSet {
            setupTableViewInset()
            setupNavItems()
            detailToolbar.setup(state: state)
            setupTapGesture()
            setupTableViewEditingMode()
            setupTextViewForPianoIfNeeded()

            Feedback.success()
        }
    }

    internal var note: Note!
    internal var dataSource: [[String]] = []
    internal var hasEdit: Bool = false

    var writeService: Writable!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerAllNotifications()
    }

    deinit {
        unRegisterAllNotifications()
    }

    /**
     노트로 셋업하는 경우
     */
    internal func setup(state: TableViewState, viewController: ViewController? = nil, note: Note? = nil) {
        registerCell(BlockCell.self)
//        registerCell(BlockHeaderCell.self)
        self.viewController = viewController
        self.note = note
        detailToolbar.pianoEditorView = self
        self.state = state

        if let note = note,
            let content = note.content {
            dataSource = []
            DispatchQueue.global().async { [weak self] in
                guard let self = self else { return }
                let contents = content.components(separatedBy: .newlines)
                DispatchQueue.main.async {

//                    if let blockHeaderCell = self.tableView.dequeueReusableCell(withIdentifier: BlockHeaderCell.reuseIdentifier) as? BlockHeaderCell,
//                        let date = note.modifiedAt {
//                        blockHeaderCell.dateLabel.text = DateFormatter.sharedInstance.string(from: date)
//                        self.tableView.tableHeaderView = blockHeaderCell.contentView
//                    }

                    self.dataSource.append(contents)
                    self.tableView.reloadData()
                }
            }
            Analytics.logEvent(viewNote: note)
        }
    }

    /**
     스트링으로 셋업하는 경우
     */
    internal func setup(state: TableViewState, viewController: ViewController? = nil, str: String) {
        registerCell(BlockCell.self)
        self.viewController = viewController

        detailToolbar.pianoEditorView = self
        self.state = state

        dataSource = []
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let contents = str.components(separatedBy: .newlines)
            DispatchQueue.main.async {

                self.dataSource.append(contents)
                self.tableView.reloadData()
            }
        }
    }

    //hasEditText 이면 전체를 실행해야함 //hasEditAttribute 이면 속성을 저장, //
    internal func saveNoteIfNeeded() {
        endEditing(true)

        guard let note = note,
            let strArray = dataSource.first, hasEdit else { return }

        let fullStr = strArray.joined(separator: "\n")
        if fullStr.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
            writeService.update(origin: note, content: fullStr)
            hasEdit = false
        }
    }

    @IBAction func tapBackground(_ sender: UITapGestureRecognizer) {
        guard !tableView.isEditing else { return }
        //터치 좌표를 계산해서 해당 터치의 y좌표, x좌표는 중앙에 셀이 없는지 체크하고, 없다면 맨 아래쪽 셀 터치한 거와 같은 동작을 하도록 구현하기
        let point = sender.location(in: self.tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        setCellBecomeFirstResponder(point: point, indexPath: indexPath)
    }

    @IBAction func tapSelect(_ sender: Any) {
        guard !tableView.isEditing else {
            tableView.setEditing(false, animated: true)
            return
        }

        state = .editing
    }

    @IBAction func tapDone(_ sender: Any) {
        state = .normal
    }

}

extension PianoEditorView: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BlockCell.reuseIdentifier) as! BlockCell
        cell.pianoEditorView = self
        cell.textView.pianoEditorView = self
        cell.textView.delegate = self
        cell.content = dataSource[indexPath.section][indexPath.row]
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].count
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let count = dataSource[indexPath.section][indexPath.row].trimmingCharacters(in: .whitespacesAndNewlines).count

        return count != 0 ? UITableViewCell.EditingStyle(rawValue: 3)! : .none

    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let count = dataSource[indexPath.section][indexPath.row].trimmingCharacters(in: .whitespacesAndNewlines).count

        if count == 0 { return false }
        if state == .piano { return false }
        if state == .editing { return true }
        if tableView.isEditing { return false }

        return true
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        guard let cell = tableView.cellForRow(at: indexPath) as? BlockCell else { return false }
        return cell.textView.text.trimmingCharacters(in: .whitespacesAndNewlines).count != 0
    }

    //    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    //        <#code#>
    //    }
}

extension PianoEditorView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        detailToolbar.changeEditingBtnsState(count: tableView.indexPathsForSelectedRows?.count ?? 0)
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        detailToolbar.changeEditingBtnsState(count: tableView.indexPathsForSelectedRows?.count ?? 0)
    }

    //    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
    //        <#code#>
    //    }

    //데이터 소스를 업데이트하고, 셀을 리로드해본다.
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        //1. 텍스트가 없거나, editing 중이라면 스와이프 할 수 없게 만들기(이상한 애니메이션 방지)
        let str = dataSource[indexPath.section][indexPath.row]
        let selectedRange = NSRange(location: 0, length: 0)
        if str.trimmingCharacters(in: .whitespacesAndNewlines).count == 0
            || tableView.isEditing {
            return nil
        }

        let eventStore = EKEventStore()

        if let headerKey = HeaderKey(text: str, selectedRange: selectedRange) {
            //2. 헤더키가 존재한다면, 본문으로 돌리는 버튼만 노출시키고, 누르면 데이터 소스에서 지우고, 리로드하기
            let resetAction = UIContextualAction(style: .normal, title: nil, handler: {[weak self] (_:UIContextualAction, _:UIView, success: (Bool) -> Void) in
                guard let self = self else { return }
                let trimStr = (str as NSString).replacingCharacters(in: headerKey.rangeToRemove, with: "")
                self.dataSource[indexPath.section][indexPath.row] = trimStr
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
                self.hasEdit = true
                success(true)

            })
            resetAction.image = #imageLiteral(resourceName: "resetH")
            resetAction.backgroundColor = Color(red: 185/255, green: 188/255, blue: 191/255, alpha: 1)
            return UISwipeActionsConfiguration(actions: [resetAction])
        } else if let reminder = str.reminderKey(store: eventStore) {
            var contextualActions: [UIContextualAction] = []
            //불렛이 있는데 그 타입이 체크리스트이면  미리알림 버튼만 노출시키기, 일정이 있다면 일정도 추가하기
            let reminderAction = UIContextualAction(style: .normal, title: nil) { [weak self](_, _, success) in
                guard let self = self, let vc = self.viewController else { return }

                Access.reminderRequest(from: vc, success: {

                    DispatchQueue.main.async {
                        (self.viewController as? DetailViewController)?.performSegue(withIdentifier: ReminderDetailViewController.identifier, sender: (eventStore, reminder))
                    }

                    success(true)
                })

            }
            reminderAction.image = #imageLiteral(resourceName: "remind")
            reminderAction.backgroundColor = Color(red: 96/255, green: 138/255, blue: 240/255, alpha: 1)
            contextualActions.append(reminderAction)
//            if let event = str.event(store: eventStore) {
//                let eventAction = UIContextualAction(style: .normal, title: nil) { [weak self](ac, view, success) in
//                    guard let self = self, let vc = self.viewController else { return }
//
//                    Access.eventRequest(from: vc, success: {
//
//                        DispatchQueue.main.async {
//
//                            let eventEditVC = EKEventEditViewController()
//                            eventEditVC.eventStore = eventStore
//                            eventEditVC.event = event
//                            if let viewController = vc as? EKEventEditViewDelegate {
//                                eventEditVC.editViewDelegate = viewController
//                            }
//                            vc.present(eventEditVC, animated: true, completion: nil)
//                        }
//
//                        success(true)
//                    })
//
//                }
//                eventAction.image = #imageLiteral(resourceName: "schedule-1")
//                eventAction.backgroundColor = Color(red: 216/255, green: 95/255, blue: 85/255, alpha: 1)
//                contextualActions.append(eventAction)
//            }

            return UISwipeActionsConfiguration(actions: contextualActions)

        } else if PianoBullet(type: .key, text: str, selectedRange: NSRange(location: 0, length: 0)) == nil {
            //불렛이 없고, 텍스트만 존재한다면, 헤더 + 미리알림 버튼 두개 노출시키기
            //3. 헤더키가 없다면 타이틀 버튼, 미리알림 버튼 노출시키기
            let titleAction = UIContextualAction(style: .normal, title: nil, handler: {[weak self] (_, _, success) in
                guard let self = self else { return }
                let title1Str = "# "
                let fullStr = title1Str + str
                self.dataSource[indexPath.section][indexPath.row] = fullStr
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
                self.hasEdit = true
                success(true)

            })

            titleAction.image = #imageLiteral(resourceName: "headline")
            titleAction.backgroundColor = Color(red: 65/255, green: 65/255, blue: 65/255, alpha: 1)

            let reminderAction = UIContextualAction(style: .normal, title: nil) { [weak self](_, _, success) in
                guard let self = self, let vc = self.viewController else { return }

                Access.reminderRequest(from: vc, success: {
                    do {
                        try eventStore.save(str.forceReminder(store: eventStore), commit: true)
                        DispatchQueue.main.async {
                            let message = "✅ Reminder is successfully Registered✨".loc
                            self.viewController?.transparentNavigationController?.show(message: message, color: Color.point)
                        }

                    } catch {
                        print("register에서 저장하다 에러: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            let message = "Please install the reminder application which is the basic application of iPhone🥰".loc
                            self.viewController?.transparentNavigationController?.show(message: message, color: Color.point)
                        }
                    }
                    success(true)
                })

            }
            reminderAction.image = #imageLiteral(resourceName: "remind")
            reminderAction.backgroundColor = Color(red: 96/255, green: 138/255, blue: 240/255, alpha: 1)

            return UISwipeActionsConfiguration(actions: [titleAction, reminderAction])
        } else {
            return nil
        }

    }

    //액션에서 하는 짓은 내가 셀에 세팅하려 하는 짓과 UI업데이트를 제외하고 똑같다(뷰에 그려질 내용을 복사하는 것이므로). 고로 이를 재사용하기 위한 코드를 셀에 만들어서 사용토록 하자.
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var str = dataSource[indexPath.section][indexPath.row]

        if str.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 || tableView.isEditing {
            return nil
        }

        //        tableView.reloadRows(at: [indexPath], with: .none)

        let copyAction = UIContextualAction(style: .normal, title: nil, handler: {[weak self] (_:UIContextualAction, _:UIView, success: (Bool) -> Void) in
            guard let self = self else { return }
            //1. bulletKey가 있다면 이모지로 변환시키기
            if let bulletKey = PianoBullet(type: .key, text: str, selectedRange: NSRange(location: 0, length: 0)) {
                str = (str as NSString).replacingCharacters(in: bulletKey.range, with: bulletKey.value)
            }

            UIPasteboard.general.string = str
            self.hasEdit = true
            success(true)

            self.viewController?.transparentNavigationController?.show(message: "✨Copied Successfully✨".loc, color: Color(red: 52/255, green: 120/255, blue: 246/255, alpha: 0.85))

        })
        copyAction.image = #imageLiteral(resourceName: "copy")
        copyAction.backgroundColor = Color(red: 65/255, green: 65/255, blue: 65/255, alpha: 1)

        let deleteAction = UIContextualAction(style: .normal, title: nil) { [weak self](_, _, success) in
            guard let self = self else { return }

            self.dataSource[indexPath.section].remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            self.hasEdit = true
            success(true)
        }
        deleteAction.image = #imageLiteral(resourceName: "Trash Icon")
        deleteAction.backgroundColor = Color(red: 234/255, green: 82/255, blue: 77/255, alpha: 1)
        return UISwipeActionsConfiguration(actions: [deleteAction, copyAction])
    }
}

extension PianoEditorView {

    private var bottomMarginOrigin: CGFloat {
        return safeAreaInsets.bottom + detailToolbar.bounds.height
    }

    private func setupTableViewInset() {
        tableView.contentInset.bottom = tableViewBottomMargin
        tableView.scrollIndicatorInsets.bottom = tableViewBottomMargin
    }

    internal func registerAllNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    internal func unRegisterAllNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func keyboardWillShow(_ notification: Notification) {

        guard let userInfo = notification.userInfo,
            let kbHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
            else { return }

        detailToolbar.animateForTyping(duration: duration, kbHeight: kbHeight)
        detailToolbar.setActivateInteraction()
        tableViewBottomMargin = kbHeight + detailToolbar.bounds.height
        state = .typing

    }

    @objc func keyboardWillHide(_ notification: Notification) {
        tableViewBottomMargin = bottomMarginOrigin
        state = .normal
        detailToolbar.setInvalidateInteraction()
        layoutIfNeeded()
    }
}

extension PianoEditorView {
    internal func setupNavItems() {
        guard let viewController = viewController else { return }
        var btns: [BarButtonItem] = []
        switch state {
        case .normal:
            let selectBtn = BarButtonItem(title: "Select".loc, style: .plain, target: self, action: #selector(tapSelect(_:)))
            btns.append(selectBtn)
            viewController.navigationItem.setLeftBarButtonItems(nil, animated: false)
        case .typing:
            viewController.navigationItem.setLeftBarButtonItems(nil, animated: false)
        case .piano:
            let leftBtns = [BarButtonItem(title: "  ", style: .plain, target: nil, action: nil)]
            viewController.navigationController?.navigationItem.setLeftBarButtonItems(leftBtns, animated: false)
            viewController.navigationItem.setLeftBarButtonItems(leftBtns, animated: false)

        case .editing:
            let doneBtn = BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(tapDone(_:)))
            btns.append(doneBtn)
            viewController.navigationItem.setLeftBarButtonItems(nil, animated: false)
        case .trash, .readOnly:
            ()
        }
        setTitleView(state: state)
        viewController.navigationItem.setRightBarButtonItems(btns, animated: false)

    }

    internal func setTitleView(state: TableViewState) {
        guard let viewController = viewController else { return }
        switch state {
        case .piano:
            if let titleView = createSubviewIfNeeded(PianoTitleView.self) {
                viewController.navigationItem.titleView = titleView
            }

        default:
            if (viewController as? DetailViewController) != nil {
                let button = UIButton(type: .system)
                button.bounds = CGRect(x: 0, y: 0, width: 250, height: 44)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 22)
                if let tags = note.tags, tags.count != 0 {
                    button.setTitle(note.tags, for: .normal)
                } else {
                    button.setImage(#imageLiteral(resourceName: "defaultTagIcon"), for: .normal)
                }

                button.addTarget(self, action: #selector(tapTagsButton(_:)), for: .touchUpInside)
                CATransaction.setCompletionBlock {
                    viewController.navigationItem.titleView = button
                }
            } else {
                viewController.navigationItem.titleView = nil
            }
        }
    }

    @IBAction func tapTagsButton(_ sender: UIButton) {
        guard let detailVC = viewController as? DetailViewController else { return }
        detailVC.performSegue(withIdentifier: AttachTagViewController.identifier, sender: sender)

    }

}

extension PianoEditorView {
    private func setupTapGesture() {
        switch state {
        case .normal, .typing:
            tapGestureRecognizer.isEnabled = true
        case .editing, .piano, .trash, .readOnly:
            tapGestureRecognizer.isEnabled = false
        }
    }

    private func setupTableViewEditingMode() {
        switch state {
        case .normal:
            tableView.setEditing(false, animated: true)
        case .editing:
            tableView.setEditing(true, animated: true)
        default:
            ()
        }
    }

    private func setupTextViewForPianoIfNeeded() {
        guard let viewController = viewController else { return }
        switch state {
        case .normal:
            viewController.navigationController?.view.subView(PianoView.self)?.removeFromSuperview()
            tableView.visibleCells.forEach {
                ($0 as? BlockCell)?.setupForPianoIfNeeded()
            }
        case .piano:
            guard let navView = viewController.navigationController?.view,
                let pianoView = navView.createSubviewIfNeeded(PianoView.self) else { return }
            pianoView.attach(on: navView)

            tableView.visibleCells.forEach {
                ($0 as? BlockCell)?.setupForPianoIfNeeded()
            }
        default:
            ()
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

    private func setCellBecomeFirstResponder(point: CGPoint, indexPath: IndexPath?) {
        if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) as? BlockCell {
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
            if let count = dataSource.first?.count, count != 0, dataSource.count != 0 {
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
}

extension PianoEditorView: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return state == .normal || state == .typing
    }

    func textViewDidChange(_ textView: UITextView) {
        guard let cell = textView.superview?.superview?.superview as? BlockCell,
            let indexPath = tableView.indexPath(for: cell) else { return }
        hasEdit = true

        //            (셀 오리진 y - 테이블뷰 오프셋 y) = 화면 상의 y값
//        let move = UIScreen.main.bounds.height - (kbHeight + detailToolbar.bounds.height + cell.frame.origin.y - tableView.contentOffset.y)

//        let a = convert(detailToolbar.frame.origin, from: tableView)
//        print(a)
//        tableView.contentInset.top = a.y - detailToolbar.frame.size.height  /
//        tableView.contentOffset.y = detailToolbar.frame.size.height - a.y

        if (cell.headerButton.title(for: .normal)?.count ?? 0) == 0 && (cell.formButton.title(for: .normal)?.count ?? 0) == 0 {

            if let headerKey = HeaderKey(text: textView.text, selectedRange: textView.selectedRange) {
                cell.convert(headerKey: headerKey)

            } else if var bulletShortcut = PianoBullet(type: .shortcut, text: textView.text, selectedRange: textView.selectedRange) {

                if bulletShortcut.isOrdered {
                    if indexPath.row != 0 {
                        let prevIndexPath = IndexPath(row: indexPath.row - 1, section: indexPath.section)
                        bulletShortcut = adjust(prevIndexPath: prevIndexPath, for: bulletShortcut)
                    }
                    cell.convert(bulletShortcut: bulletShortcut)

                    //다음셀들도 적응시킨다.
                    adjustAfter(currentIndexPath: indexPath, pianoBullet: bulletShortcut)
                } else {
                    cell.convert(bulletShortcut: bulletShortcut)
                }
            }

        }

        cell.addCheckAttrIfNeeded()
        cell.addHeaderAttrIfNeeded()
        cell.saveToDataSource()
        reactCellHeightIfNeeded(textView)

    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        detailToolbar.changeEditingAtBtnsState(count: textView.selectedRange.length)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        print("textViewDidBeginEditing")
        detailToolbar.changeEditingAtBtnsState(count: textView.selectedRange.length)

        //TODO: 타이핑중에 액션버튼 숨기기
        guard let cell = textView.superview?.superview?.superview as? BlockCell else { return }
        cell.actionButton.isHidden = true
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        //데이터 소스에 저장하기
        guard let cell = textView.superview?.superview?.superview as? BlockCell else { return }
        cell.saveToDataSource()

        if let pluginData = textView.text.pluginData {
            cell.pluginData = pluginData
            reactCellHeight()
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView.text.count > 1000 || text.count > 1000 {
            return false
        }

        guard let cell = textView.superview?.superview?.superview as? BlockCell,
            let indexPath = tableView.indexPath(for: cell) else { return true }

        let situation = typingSituation(cell: cell, indexPath: indexPath, selectedRange: textView.selectedRange, replacementText: text)

        switch situation {
        case .revertForm:
            cell.revertForm()
        case .removeForm:
            cell.removeForm()
        case .split:
            split(textView: textView, cell: cell, indexPath: indexPath)
        //데이터와 뷰 바인딩(테이블뷰셀 인서트)인 걸 만들어서 호출하기
        case .combine:
            combine(textView: textView, cell: cell, indexPath: indexPath)
        case .stayCurrent:
            return true
        }
        hasEdit = true
        UIView.performWithoutAnimation {
            tableView.performBatchUpdates(nil, completion: nil)
        }
        return false
    }

    enum TypingSituation {
        case revertForm
        case removeForm
        case combine
        case stayCurrent
        case split
    }

    private func typingSituation(cell: BlockCell,
                                 indexPath: IndexPath,
                                 selectedRange: NSRange,
                                 replacementText text: String) -> TypingSituation {

        if selectedRange == NSRange(location: 0, length: 0) {
            //문단 맨 앞에 커서가 있으면서 백스페이스 눌렀을 때
            if cell.formButton.title(for: .normal) != nil || cell.headerButton.title(for: .normal) != nil {
                //서식이 존재한다면
                if text.count == 0 {
                    return .revertForm
                } else if text == "\n" {
                    return .removeForm
                } else {
                    return .stayCurrent
                }
            }

            if indexPath.row != 0, text.count == 0 {
                //TODO: 나중에 텍스트가 아닌 다른 타입일 경우에 이전 셀이 텍스트인 지도 체크해야함
                return .combine
            }

            if text == "\n" {
                return .split
            }

            //그 외의 경우
            return .stayCurrent

        } else if text == "\n" {
            //개행을 눌렀을 때
            return .split
        } else {
            return .stayCurrent
        }
    }

    //앞쪽에 잘려 나가는 문자열은 데이터소스에 투입이 되어야 하기 때문에, 키로 전부 변환시켜줘야한다.(헤더, 서식, 피아노효과)
    //저장 로직이나 마찬가지임 -> 재사용해보기
    func split(textView: UITextView, cell: BlockCell, indexPath: IndexPath) {
        let insertRange = NSRange(location: 0, length: textView.selectedRange.lowerBound)
        let insertAttrStr = textView.attributedText.attributedSubstring(from: insertRange)
        let insertMutableAttrStr = NSMutableAttributedString(attributedString: insertAttrStr)

        //1. 피아노 효과부터 :: ::를 삽입해준다.
        var highlightRanges: [NSRange] = []
        insertMutableAttrStr.enumerateAttribute(.backgroundColor, in: NSRange(location: 0, length: insertMutableAttrStr.length), options: .reverse) { (value, range, _) in
            guard let color = value as? Color, color == Color.highlight else { return }
            highlightRanges.append(range)
        }
        //reverse로 했으므로 순차 탐색하면서 :: 넣어주면 된다.
        highlightRanges.forEach {
            insertMutableAttrStr.replaceCharacters(in: NSRange(location: $0.upperBound, length: 0), with: "::")
            insertMutableAttrStr.replaceCharacters(in: NSRange(location: $0.lowerBound, length: 0), with: "::")
        }

        //2. 버튼에 있는 걸 키로 만들어 삽입해준다.
        if let formStr = cell.headerButton.title(for: .normal),
            HeaderKey(text: formStr, selectedRange: NSRange(location: 0, length: 0)) != nil {
            let attrString = NSAttributedString(string: formStr)
            insertMutableAttrStr.insert(attrString, at: 0)

            cell.headerButton.setTitle(nil, for: .normal)
            cell.headerButton.isHidden = true
            cell.textView.textStorage.addAttributes(FormAttribute.defaultAttr, range: NSRange(location: 0, length: cell.textView.attributedText.length))

        } else if let formStr = cell.formButton.title(for: .normal),
            var bulletValue = PianoBullet(type: .value, text: formStr, selectedRange: NSRange(location: 0, length: 0)) {
            let attrString = NSAttributedString(string: bulletValue.whitespaces.string + bulletValue.key + bulletValue.followStr)
            insertMutableAttrStr.insert(attrString, at: 0)

            //3. 버튼에 있는 것이 순서 있는 서식이면 현재 버튼의 숫자를 + 1 해주고, 다음 서식들도 업데이트 해줘야 한다.
            if let currentNum = Int(bulletValue.value) {
                let nextNumStr = "\(UInt(currentNum + 1))"
                bulletValue.value = nextNumStr
                cell.setFormButton(pianoBullet: bulletValue)
                adjustAfter(currentIndexPath: indexPath, pianoBullet: bulletValue)
            }
        }

        dataSource[indexPath.section].insert(insertMutableAttrStr.string, at: indexPath.row)
        //3. 테이블 뷰 갱신시키기
        UIView.performWithoutAnimation {
            tableView.insertRows(at: [indexPath], with: .none)
        }

        //checkOn이면 checkOff로 바꿔주기
        cell.setCheckOffIfNeeded()

        //현재 셀의 텍스트뷰의 어트리뷰트는 디폴트 어트리뷰트로 세팅하여야 함
        let leaveRange = NSRange(location: textView.selectedRange.upperBound, length: textView.attributedText.length - textView.selectedRange.upperBound)
        let leaveAttrStr = textView.attributedText.attributedSubstring(from: leaveRange)

        let leaveMutableAttrStr = NSMutableAttributedString(attributedString: leaveAttrStr)
        let range = NSRange(location: 0, length: textView.attributedText.length)
        leaveMutableAttrStr.addAttributes(FormAttribute.defaultAttr, range: NSRange(location: 0, length: leaveAttrStr.length))
        textView.replaceCharacters(in: range, with: leaveMutableAttrStr)
        textView.selectedRange = NSRange(location: 0, length: 0)
        textView.typingAttributes = FormAttribute.defaultAttr

        let currentIndexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
        tableView.scrollToRow(at: currentIndexPath, at: .bottom, animated: false)
    }

    // -> 이건 해동 로직이나 마찬가지임. didSet과 재사용할 수 있는 지 고민해보기
    func combine(textView: UITextView, cell: BlockCell, indexPath: IndexPath) {
        //1. 이전 셀의 텍스트뷰 정보를 불러와서 폰트값을 세팅해줘야 하고, 텍스트를 더해줘야한다.(이미 커서가 앞에 있으니 걍 텍스트뷰의 replace를 쓰면 된다 됨), 서식이 있다면 마찬가지로 서식을 대입해줘야한다. 서식은 텍스트 대입보다 뒤에 대입을 해야, 취소선 등이 적용되게 해야한다.
        let prevIndexPath = IndexPath(row: indexPath.row - 1, section: indexPath.section)
        let prevStr = dataSource[prevIndexPath.section][prevIndexPath.row]

        // -> 이전 텍스트에서 피아노 효과만 먼저 입히기
        //TODO: 피아노 효과에 대한 것도 추가해야함
        let mutableAttrString = NSMutableAttributedString(string: prevStr, attributes: FormAttribute.defaultAttr)
        while true {
            guard let highlightKey = HighlightKey(text: mutableAttrString.string, selectedRange: NSRange(location: 0, length: mutableAttrString.length)) else { break }

            mutableAttrString.addAttributes([.backgroundColor: Color.highlight], range: highlightKey.range)
            mutableAttrString.replaceCharacters(in: highlightKey.endDoubleColonRange, with: "")
            mutableAttrString.replaceCharacters(in: highlightKey.frontDoubleColonRange, with: "")
        }

        //0. 이전 인덱스의 데이터 소스 및 셀을 지운다.
        dataSource[prevIndexPath.section].remove(at: prevIndexPath.row)
        UIView.performWithoutAnimation {
            tableView.deleteRows(at: [prevIndexPath], with: .none)
        }

        //1. 텍스트를 붙여준다.
        let attrTextLength = textView.attributedText.length
        mutableAttrString.append(textView.attributedText)
        //뒤에 문자열이 있다면,
        //3. 커서를 배치시킨다음 서식이 잘릴 걸 예상해서 replaceCharacters를 호출한다

        if let pianoBullet = PianoBullet(type: .key, text: mutableAttrString.string, selectedRange: NSRange(location: 0, length: 0)) {
            let attrString = NSAttributedString(string: pianoBullet.userDefineForm.shortcut, attributes: FormAttribute.defaultAttr)
            mutableAttrString.replaceCharacters(in: pianoBullet.range, with: attrString)
        }

        textView.replaceCharacters(in: NSRange(location: 0, length: attrTextLength), with: mutableAttrString)
        textView.selectedRange = NSRange(location: textView.attributedText.length - attrTextLength, length: 0)

        tableView.scrollToRow(at: prevIndexPath, at: .bottom, animated: false)
    }

    private func adjustAfter(currentIndexPath: IndexPath, pianoBullet: PianoBullet) {
        var pianoBullet = pianoBullet
        var indexPath = IndexPath(row: currentIndexPath.row + 1, section: currentIndexPath.section)
        while indexPath.row < tableView.numberOfRows(inSection: 0) {
            let str = dataSource[indexPath.section][indexPath.row]
            guard let nextBulletKey = PianoBullet(type: .key, text: str, selectedRange: NSRange(location: 0, length: 0)),
                pianoBullet.whitespaces.string == nextBulletKey.whitespaces.string,
                let currentNum = UInt(pianoBullet.value),
                nextBulletKey.isOrdered,
                !pianoBullet.isSequencial(next: nextBulletKey)  else { return }

            //1. check overflow
            let nextNumStr = "\(currentNum + 1)"
            pianoBullet.value = nextNumStr
            guard !pianoBullet.isOverflow else { return }

            //2. set datasource
            let newStr = (str as NSString).replacingCharacters(in: nextBulletKey.range, with: nextNumStr)
            dataSource[indexPath.section][indexPath.row] = newStr

            //3. set view
            if let cell = tableView.cellForRow(at: indexPath) as? BlockCell {
                cell.setFormButton(pianoBullet: pianoBullet)
            }

            indexPath.row += 1
        }

    }

    private func adjust(prevIndexPath: IndexPath, for bulletKey: PianoBullet) -> PianoBullet {
        //이전 셀이 존재하고, 그 셀이 넘버 타입이고, whitespace까지 같다면, 그 셀 + 1한 값을 bulletKey의 value에 대입
        let str = dataSource[prevIndexPath.section][prevIndexPath.row]
        guard let prevBulletKey = PianoBullet(type: .key, text: str, selectedRange: NSRange(location: 0, length: 0)),
            let num = Int(prevBulletKey.value),
            prevBulletKey.whitespaces.string == bulletKey.whitespaces.string
            else { return bulletKey }
        var bulletKey = bulletKey
        bulletKey.value = "\(num + 1)"
        return bulletKey
    }

    internal func reactCellHeightIfNeeded(_ textView: UITextView) {
        let index = textView.attributedText.length - 1
        guard index > -1 else {
            UIView.performWithoutAnimation {
                tableView.performBatchUpdates(nil, completion: nil)
            }
            return
        }

        let lastLineRect = textView.layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: nil)
        let textViewHeight = textView.bounds.height
        //TODO: 테스트해보면서 20값 해결하기
        guard textView.layoutManager.location(forGlyphAt: index).y == 0
            || textViewHeight - (lastLineRect.origin.y + lastLineRect.height) > 20 else {
                return
        }

        UIView.performWithoutAnimation {
            tableView.performBatchUpdates(nil, completion: nil)
        }
    }

    internal func reactCellHeight() {
        UIView.performWithoutAnimation {
            tableView.performBatchUpdates(nil, completion: nil)
        }
    }
}
