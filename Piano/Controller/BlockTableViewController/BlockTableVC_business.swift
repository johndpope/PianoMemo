//
//  BlockTableVC_business.swift
//  Piano
//
//  Created by Kevin Kim on 21/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation
import EventKit

extension BlockTableViewController {
    internal func setup() {
        blockTableState = .normal(.read)
        setupForMerge()
        setupForDataSource()
        setBackgroundViewForTouchEvent()
    }

    @objc internal func saveNoteIfNeeded(needToSave: Bool = false) {
        //TextViewDelegate의 endEditing을 통해 저장을 유도
        guard let note = note,
            let strArray = dataSource.first else { return }
        let content = strArray.joined(separator: "\n")
        if content != note.content {
            noteHandler.update(
                origin: note,
                content: content,
                needToSave: needToSave
            )
        }
    }

    internal func configure(cell: TextBlockTableViewCell, indexPath: IndexPath) {
        cell.blockTableVC = self
        cell.textView.blockTableVC = self
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
        guard let cell = tableView.cellForRow(at: indexPath) as? TextBlockTableViewCell,
            tableView.numberOfRows(inSection: 0) == 1,
            cell.textView.text.count == 0 else { return }
        if !cell.textView.isFirstResponder {
            cell.textView.becomeFirstResponder()
        }
    }

    //텍스트가 없거나, editing 중이라면, 스와이프 할 수 없게 만들기
    internal func canSwipe(str: String) -> Bool {
        return str.trimmingCharacters(in: .whitespacesAndNewlines).count != 0
            && !tableView.isEditing
    }

    private func setBackgroundViewForTouchEvent() {

        let view = View()
        view.backgroundColor = .clear
        let tapGestureRecognizer = TapGestureRecognizer(target: self, action: #selector(tapBackground(_:)))
        view.addGestureRecognizer(tapGestureRecognizer)
        self.tableView.backgroundView = view
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
            ($0 as? TextBlockTableViewCell)?.setupForPianoIfNeeded()
        }
    }

    internal func resetAction(_ str: String, _ headerKey: HeaderKey, _ indexPath: IndexPath) -> ContextualAction {
        //2. 헤더키가 존재한다면, 본문으로 돌리는 버튼만 노출시키고, 누르면 데이터 소스에서 지우고, 리로드하기
        let resetAction = ContextualAction(style: .normal, title: nil) { [weak self](_, _, success) in
            guard let self = self else { return }
            let trimStr = (str as NSString).replacingCharacters(in: headerKey.rangeToRemove, with: "")
            self.dataSource[indexPath.section][indexPath.row] = trimStr
            View.performWithoutAnimation {
                self.tableView.reloadRows(at: [indexPath], with: .none)
            }
            success(true)
        }
        resetAction.image = #imageLiteral(resourceName: "resetH")
        resetAction.backgroundColor = Color(red: 185/255, green: 188/255, blue: 191/255, alpha: 1)
        return resetAction
    }

    internal func reminderAction(_ reminder: EKReminder, _ eventStore: EKEventStore) -> ContextualAction {
        let reminderAction = ContextualAction(style: .normal, title: nil) { [weak self](_, _, success) in
            guard let self = self else { return }
            Access.reminderRequest(from: self, success: {
                DispatchQueue.main.async {
                    do {
                        try eventStore.save(reminder, commit: true)
                        let message = "✅ Reminder is successfully Registered✨".loc
                        self.transparentNavigationController?.show(message: message, color: Color.point)
                    } catch {
                        print(error.localizedDescription)
                        DispatchQueue.main.async {
                            let message = "Please install the reminder application which is the basic application of iPhone🥰".loc
                            self.transparentNavigationController?.show(message: message, color: Color.point)
                        }
                    }
                }
            })
        }
        reminderAction.image = #imageLiteral(resourceName: "remind")
        reminderAction.backgroundColor = Color(red: 96/255, green: 138/255, blue: 240/255, alpha: 1)
        return reminderAction
    }

    internal func titleAction(_ str: String, _ indexPath: IndexPath) -> ContextualAction {
        //불렛이 없고, 텍스트만 존재한다면, 헤더 + 미리알림 버튼 두개 노출시키기
        //3. 헤더키가 없다면 타이틀 버튼, 미리알림 버튼 노출시키기
        let titleAction = ContextualAction(style: .normal, title: nil) { [weak self](_, _, success) in
            guard let self = self else { return }
            let title1Str = "# "
            let fullStr = title1Str + str
            self.dataSource[indexPath.section][indexPath.row] = fullStr
            
            View.performWithoutAnimation {
                self.tableView.reloadRows(at: [indexPath], with: .none)
            }
            success(true)
        }
        titleAction.image = #imageLiteral(resourceName: "h1")
        titleAction.backgroundColor = Color(red: 65/255, green: 65/255, blue: 65/255, alpha: 1)
        return titleAction
    }

    internal func copyAction(_ str: String) -> ContextualAction {
        let copyAction = ContextualAction(style: .normal, title: nil, handler: {[weak self] (_:ContextualAction, _:View, success: (Bool) -> Void) in
            guard let self = self else { return }
            var str = str
            //1. bulletKey가 있다면 이모지로 변환시키기
            if let bulletKey = PianoBullet(type: .key, text: str, selectedRange: NSRange(location: 0, length: 0)) {
                str = (str as NSString).replacingCharacters(in: bulletKey.range, with: bulletKey.value)
            }

            Pasteboard.general.string = str
            success(true)

            self.transparentNavigationController?.show(message: "✨Copied Successfully✨".loc, color: Color(red: 52/255, green: 120/255, blue: 246/255, alpha: 0.85))

        })
        copyAction.image = #imageLiteral(resourceName: "copy")
        copyAction.backgroundColor = Color(red: 65/255, green: 65/255, blue: 65/255, alpha: 1)
        return copyAction
    }

    internal func deleteAction(_ indexPath: IndexPath) -> ContextualAction {
        let deleteAction = ContextualAction(style: .normal, title: nil) { [weak self](_, _, success) in
            guard let self = self else { return }
            
            self.dataSource[indexPath.section].remove(at: indexPath.row)
            View.performWithoutAnimation {
                self.tableView.deleteRows(at: [indexPath], with: .none)
            }

            success(true)
        }
        deleteAction.image = #imageLiteral(resourceName: "Trash Icon")
        deleteAction.backgroundColor = Color(red: 234/255, green: 82/255, blue: 77/255, alpha: 1)
        return deleteAction
    }
}
