//
//  Detail2ViewController.swift
//  Piano
//
//  Created by Kevin Kim on 22/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import CloudKit
import MobileCoreServices


/**
 textViewDidEndEditing에서 데이터 소스에 업로드가 된다. (업로드 될 때에는 뷰의 모든 정보가 키 값으로 변환되어서 텍스트에 저장된다)
 cellForRow에선 단순히 string을 넣어주는 역할만 한다.
 모든 변환은 cell이 하고 있으며
 데이터 인풋인 텍스트뷰가 하고 있다.
 텍스트 안에 있는 키 값들로 효과를 입힌다.
 leading,trailing 액션들을 시행할 경우, 데이터 소스와 뷰가 모두 같이 변한다.
 */

class Detail2ViewController: UIViewController {
    
    enum VCState {
        case normal
        case editing
        case typing
        case piano
    }
    var state: VCState = .normal {
        didSet {
            setupNavigationItems()
            detailToolbar.setup(state: state)
            
            switch state {
            case .normal:
                tapGestureRecognizer.isEnabled = true
                tableView.setEditing(false, animated: true)
                
            case .typing:
                ()
            case .editing:
                view.endEditing(true)
                tapGestureRecognizer.isEnabled = false
                tableView.setEditing(true, animated: true)
            
            case .piano:
                ()
            }
        }
    }
    
    
    @IBOutlet weak var detailToolbar: DetailToolbar!
    @IBOutlet weak var tapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var tableView: UITableView!
    var dataSource: [[String]] = []
    var hasEdit = false
    var note: Note?
    weak var storageService: StorageService!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if storageService == nil {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                self.storageService = appDelegate.storageService
            }
        } else {
            setup()
        }
    }

    private func setup() {
        setupDelegate()
        setupDataSource()
        state = .normal
        //        addNotification()
    }
    
    internal func setupDataSource() {
        guard let note = note, let content = note.content else { return }
        dataSource = []
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let contents = content.components(separatedBy: .newlines)
            self.dataSource.append(contents)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    private func setupDelegate() {
        detailToolbar.detail2ViewController = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerAllNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        super.view.endEditing(true)
        unRegisterAllNotifications()
        saveNoteIfNeeded()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? PianoEditorViewController {
            vc.note = self.note
            return
        }
        
        if let des = segue.destination as? AttachTagCollectionViewController {
            des.note = note
            des.detailVC = self
            des.storageService = storageService
            return
        }
        
        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? MergeTableViewController {
            vc.originNote = note
            vc.storageService = storageService
            vc.detailVC = self
            return
        }
    }
}

extension Detail2ViewController {
    internal func registerAllNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeDidChangeNotification(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeStatusBarOrientation(_:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    internal func unRegisterAllNotifications(){
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func contentSizeDidChangeNotification(_ notification: Notification) {
        guard let note = note else { return }
//        textView.setup(note: note) { _ in }
    }
    
    @objc func didChangeStatusBarOrientation(_ notification: Notification) {
//        if let pianoControl = textView.pianoControl,
//            let pianoView = pianoView,
//            !textView.isSelectable {
//            connect(pianoView: pianoView, pianoControl: pianoControl, textView: textView)
//            pianoControl.attach(on: textView)
//        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
//        coordinator.animate(alongsideTransition: nil) {[unowned self] (_) in
//            guard let textView = self.textView else { return }
//            if let pianoControl = textView.pianoControl,
//                let pianoView = self.pianoView,
//                !textView.isSelectable {
//                self.connect(pianoView: pianoView, pianoControl: pianoControl, textView: textView)
//                pianoControl.attach(on: textView)
//            }
//        }
    }

    override func encodeRestorableState(with coder: NSCoder) {
        guard let note = note else { return }
        coder.encode(note.objectID.uriRepresentation(), forKey: "noteURI")
        super.encodeRestorableState(with: coder)
    }

    override func decodeRestorableState(with coder: NSCoder) {
        if let url = coder.decodeObject(forKey: "noteURI") as? URL {
            storageService.local.note(url: url) { note in
                OperationQueue.main.addOperation { [weak self] in
                    guard let self = self else { return }
                    self.note = note
                    self.setup()
                }
            }
        }
        super.decodeRestorableState(with: coder)
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        setTableViewInsetNormal()
        state = .normal
        detailToolbar.keyboardToken?.invalidate()
        detailToolbar.keyboardToken = nil
        view.layoutIfNeeded()
    }
    
    private func setTableViewInsetNormal(){
        tableView.contentInset.bottom = 100
        tableView.scrollIndicatorInsets.bottom = 0
    }
    
    //hasEditText 이면 전체를 실행해야함 //hasEditAttribute 이면 속성을 저장, //
    internal func saveNoteIfNeeded() {
        self.view.endEditing(true)

        guard let note = note,
            let strArray = dataSource.first, hasEdit else { return }
        
        let fullStr = strArray.joined(separator: "\n")
        storageService.local.update(note: note, string: fullStr)
        hasEdit = false
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            let kbHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
            else { return }
        
        let safeAreaInset = view.safeAreaInsets.bottom
        state = .typing
        
        UIView.animate(withDuration: duration) { [weak self] in
            guard let self = self else { return }
            self.detailToolbar.detailToolbarBottomAnchor.constant = kbHeight - safeAreaInset
            self.detailToolbar.frame.size.height = 44
            self.setTableViewInsetTyping(kbHeight: kbHeight)
            self.view.layoutIfNeeded()
        }
        
        detailToolbar.keyboardToken = UIApplication.shared.windows[1].subviews.first?.subviews.first?.layer.observe(\.position, changeHandler: { [weak self](layer, change) in
            guard let `self` = self else { return }
        
            self.detailToolbar.detailToolbarBottomAnchor.constant = max(UIScreen.main.bounds.height - layer.frame.origin.y - safeAreaInset, 0)
            self.view.layoutIfNeeded()
        })
        
    }

    
    private func setTableViewInsetTyping(kbHeight: CGFloat) {
        let height = kbHeight
        tableView.contentInset.bottom = height + detailToolbar.bounds.height
        tableView.scrollIndicatorInsets.bottom = height + detailToolbar.bounds.height
    }
}

extension Detail2ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BlockCell.reuseIdentifier) as! BlockCell
        cell.detailVC = self
        cell.textView.detailVC = self
        let content = dataSource[indexPath.section][indexPath.row]
        cell.content = content
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    private func dateStr(from note: Note?) -> String {
        if let date = note?.modifiedAt {
            let string = DateFormatter.sharedInstance.string(from: date)
            return string
        } else {
            return "Play your thought"
        }
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

extension Detail2ViewController: UITableViewDelegate {
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
        //1. 텍스트가 없거나, 불렛이 존재한다면 스와이프할 수 없게끔 만들기
        let str = dataSource[indexPath.section][indexPath.row]
        let selectedRange = NSMakeRange(0, 0)
        if str.trimmingCharacters(in: .whitespacesAndNewlines).count == 0
            || BulletKey(text: str, selectedRange: selectedRange) != nil
            || tableView.isEditing {
            return nil
        }
        
//        tableView.reloadRows(at: [indexPath], with: .none)
        
        if let headerKey = HeaderKey(text: str, selectedRange: selectedRange) {
            //2. 헤더키가 존재한다면, 본문으로 돌리는 버튼만 노출시키고, 누르면 데이터 소스에서 지우고, 리로드하기
            let resetAction = UIContextualAction(style: .normal, title: nil, handler: {[weak self] (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
                guard let self = self else { return }
                let trimStr = (str as NSString).replacingCharacters(in: headerKey.rangeToRemove, with: "")
                self.dataSource[indexPath.section][indexPath.row] = trimStr
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
                self.hasEdit = true
                success(true)
                
                
            })
            resetAction.image = #imageLiteral(resourceName: "undo")
            resetAction.backgroundColor = Color.trash
            return UISwipeActionsConfiguration(actions: [resetAction])
        } else {
            //3. 헤더키가 없다면 타이틀1,2,3 버튼 노출시키기
            let title1Action = UIContextualAction(style: .normal, title: nil, handler: {[weak self] (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
                guard let self = self else { return }
                let title1Str = "# "
                let fullStr = title1Str + str
                self.dataSource[indexPath.section][indexPath.row] = fullStr
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
                self.hasEdit = true
                success(true)
                
            })
            title1Action.image = #imageLiteral(resourceName: "copy")
            title1Action.backgroundColor = Color.green
            
            let title2Action = UIContextualAction(style: .normal, title: nil, handler: {[weak self] (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
                guard let self = self else { return }
                let title2Str = "## "
                let fullStr = title2Str + str
                self.dataSource[indexPath.section][indexPath.row] = fullStr
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
                self.hasEdit = true
                success(true)
                
            })
            title2Action.image = #imageLiteral(resourceName: "copy")
            title2Action.backgroundColor = Color.purple
            
            let title3Action = UIContextualAction(style: .normal, title: nil, handler: {[weak self] (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
                guard let self = self else { return }
                let title3Str = "### "
                let fullStr = title3Str + str
                self.dataSource[indexPath.section][indexPath.row] = fullStr
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
                self.hasEdit = true
                success(true)
                
            })
            title3Action.image = #imageLiteral(resourceName: "copy")
            title3Action.backgroundColor = Color.yellow
            return UISwipeActionsConfiguration(actions: [title1Action, title2Action, title3Action])
            
        }
    }

    //액션에서 하는 짓은 내가 셀에 세팅하려 하는 짓과 UI업데이트를 제외하고 똑같다(뷰에 그려질 내용을 복사하는 것이므로). 고로 이를 재사용하기 위한 코드를 셀에 만들어서 사용토록 하자.
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var str = dataSource[indexPath.section][indexPath.row]

        if str.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 || tableView.isEditing {
            return nil
        }
        
//        tableView.reloadRows(at: [indexPath], with: .none)

        let copyAction = UIContextualAction(style: .normal, title: nil, handler: {[weak self] (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            guard let self = self else { return }
            //1. bulletKey가 있다면 이모지로 변환시키기
            if let bulletKey = BulletKey(text: str, selectedRange: NSMakeRange(0, 0)) {
                str = (str as NSString).replacingCharacters(in: bulletKey.range, with: bulletKey.value)
            }
            
            UIPasteboard.general.string = str
            self.hasEdit = true
            success(true)
            
            
        })
        copyAction.image = #imageLiteral(resourceName: "copy")
        copyAction.backgroundColor = Color.point
        
        let deleteAction = UIContextualAction(style: .normal, title: nil) { [weak self](ac, view, success) in
            guard let self = self else { return }
            
            self.dataSource[indexPath.section].remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            self.hasEdit = true
            success(true)
        }
        deleteAction.image = #imageLiteral(resourceName: "Trash Icon")
        deleteAction.backgroundColor = Color.red
        return UISwipeActionsConfiguration(actions: [deleteAction, copyAction])
    }
}

extension Detail2ViewController: UITextViewDelegate {
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return state == .normal || state == .typing
    }
    
    func textViewDidChange(_ textView: UITextView) {
        guard let cell = textView.superview?.superview?.superview as? BlockCell,
            let indexPath = tableView.indexPath(for: cell) else { return }
        hasEdit = true
        
        if (cell.formButton.title(for: .normal)?.count ?? 0) == 0,
            let headerKey = HeaderKey(text: textView.text, selectedRange: textView.selectedRange) {
            cell.convertHeader(headerKey: headerKey)

        } else if (cell.formButton.title(for: .normal)?.count ?? 0) == 0,
            var bulletKey = BulletKey(text: textView.text, selectedRange: textView.selectedRange) {
            switch bulletKey.type {
            case .orderedlist:
                if indexPath.row != 0 {
                    let prevIndexPath = IndexPath(row: indexPath.row - 1, section: indexPath.section)
                    bulletKey = adjust(prevIndexPath: prevIndexPath, for: bulletKey)
                }
                
                cell.convertForm(bulletable: bulletKey)
                
                //다음셀들도 적응시킨다.
                adjustAfter(currentIndexPath: indexPath, bulletable: bulletKey)
                
            default:
                cell.convertForm(bulletable: bulletKey)
            }
        }
        
        cell.addCheckAttrIfNeeded()
        cell.addHeaderAttrIfNeeded()
        cell.saveToDataSource()
        reactCellHeight(textView)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        //TODO: 뭘 해야하나..?
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        //데이터 소스에 저장하기
        guard let cell = textView.superview?.superview?.superview as? BlockCell else { return }
        cell.saveToDataSource()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
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
        
        if selectedRange == NSMakeRange(0, 0) {
            //문단 맨 앞에 커서가 있으면서 백스페이스 눌렀을 때
            if cell.formButton.title(for: .normal) != nil {
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
        let insertRange = NSMakeRange(0, textView.selectedRange.lowerBound)
        let insertAttrStr = textView.attributedText.attributedSubstring(from: insertRange)
        let insertMutableAttrStr = NSMutableAttributedString(attributedString: insertAttrStr)
        
        //1. 피아노 효과부터 :: ::를 삽입해준다.
        var highlightRanges: [NSRange] = []
        insertMutableAttrStr.enumerateAttribute(.backgroundColor, in: NSMakeRange(0, insertMutableAttrStr.length), options: .reverse) { (value, range, _) in
            guard let color = value as? Color, color == Color.highlight else { return }
            highlightRanges.append(range)
        }
        //reverse로 했으므로 순차 탐색하면서 :: 넣어주면 된다.
        highlightRanges.forEach {
            insertMutableAttrStr.replaceCharacters(in: NSMakeRange($0.upperBound, 0), with: "::")
            insertMutableAttrStr.replaceCharacters(in: NSMakeRange($0.lowerBound, 0), with: "::")
        }
        
        //2. 버튼에 있는 걸 키로 만들어 삽입해준다.
        if let formStr = cell.formButton.title(for: .normal),
            let _ = HeaderKey(text: formStr, selectedRange: NSMakeRange(0, 0)) {
            let attrString = NSAttributedString(string: formStr)
            insertMutableAttrStr.insert(attrString, at: 0)
            
            cell.formButton.setTitle(nil, for: .normal)
            cell.formButton.isHidden = true
            
            cell.textView.textStorage.addAttributes(FormAttribute.defaultAttr, range: NSMakeRange(0, cell.textView.attributedText.length))
            
            
        } else if let formStr = cell.formButton.title(for: .normal),
            var bulletValue = BulletValue(text: formStr, selectedRange: NSMakeRange(0, 0)) {
            let attrString = NSAttributedString(string: bulletValue.whitespaces.string + bulletValue.key + bulletValue.followStr)
            insertMutableAttrStr.insert(attrString, at: 0)
            
            //3. 버튼에 있는 것이 순서 있는 서식이면 현재 버튼의 숫자를 + 1 해주고, 다음 서식들도 업데이트 해줘야 한다.
            if let currentNum = Int(bulletValue.string) {
                let nextNumStr = "\(UInt(currentNum + 1))"
                bulletValue.string = nextNumStr
                cell.setFormButton(bulletable: bulletValue)
                adjustAfter(currentIndexPath: indexPath, bulletable: bulletValue)
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
        let leaveRange = NSMakeRange(textView.selectedRange.upperBound,
                                     textView.attributedText.length - textView.selectedRange.upperBound)
        let leaveAttrStr = textView.attributedText.attributedSubstring(from: leaveRange)
        
        
        let leaveMutableAttrStr = NSMutableAttributedString(attributedString: leaveAttrStr)
        let range = NSMakeRange(0, textView.attributedText.length)
        leaveMutableAttrStr.addAttributes(FormAttribute.defaultAttr, range: NSMakeRange(0, leaveAttrStr.length))
        textView.replaceCharacters(in: range, with: leaveMutableAttrStr)
        textView.selectedRange = NSMakeRange(0, 0)
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
            guard let highlightKey = HighlightKey(text: mutableAttrString.string, selectedRange: NSMakeRange(0, mutableAttrString.length)) else { break }
            
            mutableAttrString.addAttributes([.backgroundColor : Color.highlight], range: highlightKey.range)
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
        
        textView.replaceCharacters(in: NSMakeRange(0, attrTextLength), with: mutableAttrString)
        textView.selectedRange = NSMakeRange(textView.attributedText.length - attrTextLength, 0)
    }
    
    private func adjustAfter(currentIndexPath: IndexPath, bulletable: Bulletable) {
         var bulletable = bulletable
        var indexPath = IndexPath(row: currentIndexPath.row + 1, section: currentIndexPath.section)
        while indexPath.row < tableView.numberOfRows(inSection: 0) {
            let str = dataSource[indexPath.section][indexPath.row]
            guard let nextBulletKey = BulletKey(text: str, selectedRange: NSMakeRange(0, 0)),
                bulletable.whitespaces.string == nextBulletKey.whitespaces.string,
                let currentNum = UInt(bulletable.string),
                nextBulletKey.type == .orderedlist,
                !bulletable.isSequencial(next: nextBulletKey)  else { return }
            
            //1. check overflow
            let nextNumStr = "\(currentNum + 1)"
            bulletable.string = nextNumStr
            guard !bulletable.isOverflow else { return }
            
            //2. set datasource
            let newStr = (str as NSString).replacingCharacters(in: nextBulletKey.range, with: nextNumStr)
            dataSource[indexPath.section][indexPath.row] = newStr
            
            //3. set view
            if let cell = tableView.cellForRow(at: indexPath) as? BlockCell {
                cell.setFormButton(bulletable: bulletable)
            }
            
            indexPath.row += 1
        }
        
    }
    
    private func adjust(prevIndexPath: IndexPath, for bulletKey: BulletKey) -> BulletKey {
        //이전 셀이 존재하고, 그 셀이 넘버 타입이고, whitespace까지 같다면, 그 셀 + 1한 값을 bulletKey의 value에 대입
        let str = dataSource[prevIndexPath.section][prevIndexPath.row]
        guard let prevBulletKey = BulletKey(text: str, selectedRange: NSMakeRange(0, 0)),
            let num = Int(prevBulletKey.string),
            prevBulletKey.whitespaces.string == bulletKey.whitespaces.string
            else { return bulletKey }
        var bulletKey = bulletKey
        bulletKey.string = "\(num + 1)"
        return bulletKey
    }
    
    internal func reactCellHeight(_ textView: UITextView) {
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
}

//MARK: Action
extension Detail2ViewController {
    @IBAction func tapBackground(_ sender: UITapGestureRecognizer) {
        guard !tableView.isEditing else { return }
        //터치 좌표를 계산해서 해당 터치의 y좌표, x좌표는 중앙에 셀이 없는지 체크하고, 없다면 맨 아래쪽 셀 터치한 거와 같은 동작을 하도록 구현하기
        let point = sender.location(in: self.tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        setCellBecomeFirstResponder(point: point, indexPath: indexPath)
    }
    
    private func setCellBecomeFirstResponder(point: CGPoint, indexPath: IndexPath?) {
        if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) as? BlockCell{
            if point.x < self.tableView.center.x {
                //앞쪽에 배치
                cell.textView.selectedRange = NSMakeRange(0, 0)
                if !cell.textView.isFirstResponder {
                    cell.textView.becomeFirstResponder()
                }
            } else {
                //뒤쪽에 배치
                cell.textView.selectedRange = NSMakeRange(cell.textView.attributedText.length, 0)
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
                cell.textView.selectedRange = NSMakeRange(cell.textView.attributedText.length, 0)
                if !cell.textView.isFirstResponder {
                    cell.textView.becomeFirstResponder()
                }
                
            }
        }
        
        
        
    }
}

extension Detail2ViewController {
    
    @objc func changeTag(_ sender: Any) {
        performSegue(withIdentifier: AttachTagCollectionViewController.identifier, sender: nil)
    }
    
    internal func setupNavigationItems(){
        var btns: [BarButtonItem] = []
        switch state {
        case .normal:
            let editBtn = BarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(tapEdit(_:)))
            btns.append(editBtn)
            navigationItem.setLeftBarButtonItems(nil, animated: false)
        case .typing:
            let editBtn = BarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(tapEdit(_:)))
            btns.append(editBtn)
            navigationItem.setLeftBarButtonItems(nil, animated: false)
        case .piano:
            let leftBtns = [BarButtonItem(title: "  ", style: .plain, target: nil, action: nil)]
            navigationController?.navigationItem.setLeftBarButtonItems(leftBtns, animated: false)
            navigationItem.setLeftBarButtonItems(leftBtns, animated: false)
            
        case .editing:
            let doneBtn = BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(tapDone(_:)))
            btns.append(doneBtn)
            navigationItem.setLeftBarButtonItems(nil, animated: false)
        }
        setTitleView(state: state)
        navigationItem.setRightBarButtonItems(btns, animated: false)
    }
    
    internal func setTitleView(state: VCState) {
        switch state {
        case .piano:
            if let titleView = view.createSubviewIfNeeded(PianoTitleView.self) {
                titleView.set(text: "Swipe over the text you want to copy✨".loc)
                navigationItem.titleView = titleView
            }
            
        default:
            let tagButton = UIButton(type: .system)
            tagButton.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 200, height: 44))
            tagButton.addTarget(self, action: #selector(changeTag(_:)), for: .touchUpInside)
            navigationItem.titleView = tagButton
            
            setupTagToNavItem()
        }
    }
    
    @IBAction func restore(_ sender: Any) {
        guard let note = note else { return }
        storageService.local.restore(note: note, completion: {})
        // dismiss(animated: true, completion: nil)
    }
    
//    @IBAction func addPeople(_ sender: Any) {
//        Feedback.success()
//        guard let note = note,
//            let item = sender as? UIBarButtonItem else {return}
//        // TODO: 네트워크 불능이거나, 아직 업로드 안 된 경우 처리
//        cloudSharingController(note: note, item: item) {
//            [weak self] controller in
//            if let self = self, let controller = controller {
//                OperationQueue.main.addOperation {
//                    self.present(controller, animated: true)
//                }
//            }
//        }
//    }
    
    @IBAction func tapEdit(_ sender: Any) {
        state = .editing
    }
    
    @IBAction func tapDone(_ sender: Any) {
        state = .normal
    }
    
    @IBAction func tapAttachTag(_ sender: Any) {
        guard let _ = note else { return }
        performSegue(withIdentifier: AttachTagCollectionViewController.identifier, sender: nil)
    }
    
    internal func setupTagToNavItem() {
        guard let note = note,
            let tagBtn = navigationItem.titleView as? UIButton else { return }
        let tags = note.tags ?? ""
        if tags.count != 0 {
            tagBtn.setImage(nil, for: .normal)
            tagBtn.setTitle(tags, for: .normal)
            
        } else {
            tagBtn.setImage(#imageLiteral(resourceName: "addTag"), for: .normal)
            tagBtn.setTitle("", for: .normal)
        }
    }
}

extension Detail2ViewController {
    func cloudSharingController(
        note: Note,
        item: UIBarButtonItem,
        completion: @escaping (UICloudSharingController?) -> Void)  {
        
        guard let record = note.recordArchive?.ckRecorded else { return }
        
        if let recordID = record.share?.recordID {
            storageService.remote.requestFetchRecords(by: [recordID], isMine: note.isMine) {
                [weak self] recordsByRecordID, operationError in
                if let self = self,
                    let dict = recordsByRecordID,
                    let share = dict[recordID] as? CKShare {
                    
                    let controller = UICloudSharingController(
                        share: share,
                        container: self.storageService.remote.container
                    )
                    controller.delegate = self
                    controller.popoverPresentationController?.barButtonItem = item
                    completion(controller)
                }
            }
        } else {
            let controller = UICloudSharingController {
                [weak self] controller, preparationHandler in
                guard let self = self else { return }
                self.storageService.remote.requestShare(recordToShare: record, preparationHandler: preparationHandler)
            }
            controller.delegate = self
            controller.popoverPresentationController?.barButtonItem = item
            completion(controller)
        }
    }
}

extension Detail2ViewController: UICloudSharingControllerDelegate {
    func cloudSharingController(
        _ csc: UICloudSharingController,
        failedToSaveShareWithError error: Error) {
        
        if let ckError = error as? CKError {
            if ckError.isSpecificErrorCode(code: .serverRecordChanged) {
                guard let note = note,
                    let recordID = note.recordArchive?.ckRecorded?.recordID else { return }
                
                storageService.remote.requestAddFetchedRecords(by: [recordID], isMine: note.isMine) {}
            }
        } else {
            print(error.localizedDescription)
        }
    }
    
    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        // 메세지 화면 수준에서 나오면 불림
        guard let note = note,
            let recordID = note.recordArchive?.ckRecorded?.recordID else { return }
        
        if csc.share == nil {
            storageService.local.update(note: note, isShared: false) {
                OperationQueue.main.addOperation { [weak self] in
                    guard let self = self else { return }
                    //TODO:
//                    self.setNavigationItems(state: self.state)
                }
            }
        }
        
        storageService.remote.requestAddFetchedRecords(by: [recordID], isMine: note.isMine) {
            OperationQueue.main.addOperation { [weak self] in
                guard let self = self else { return }
                //TODO:
//                self.setNavigationItems(state: self.state)
            }
        }
    }
    
    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        // 메시지로 공유한 후 불림
        // csc.share == nil
        // 성공 후에 불림
        guard let note = note,
            let recordID = note.recordArchive?.ckRecorded?.recordID else { return }
        
        if csc.share != nil {
            
            storageService.local.update(note: note, isShared: true) {
                OperationQueue.main.addOperation { [weak self] in
                    guard let self = self else { return }
                    //TODO:
//                    self.setNavigationItems(state: self.state)
                }
            }
            storageService.remote.requestAddFetchedRecords(by: [recordID], isMine: note.isMine) {
                OperationQueue.main.addOperation { [weak self] in
                    guard let self = self else { return }
                    //TODO:
//                    self.setNavigationItems(state: self.state)
                }
            }
        }
    }
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        return note?.title
    }
    
    func itemType(for csc: UICloudSharingController) -> String? {
        return kUTTypeContent as String
    }
    
    func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
        return nil
        //TODO:
//        return textView.capture()
    }
}

private extension UIView {
    func capture() -> Data? {
        var image: UIImage?
        if #available(iOS 10.0, *) {
            let format = UIGraphicsImageRendererFormat()
            format.opaque = isOpaque
            let renderer = UIGraphicsImageRenderer(size: frame.size, format: format)
            image = renderer.image { context in
                drawHierarchy(in: frame, afterScreenUpdates: true)
            }
        } else {
            UIGraphicsBeginImageContextWithOptions(frame.size, isOpaque, UIScreen.main.scale)
            drawHierarchy(in: frame, afterScreenUpdates: true)
            image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        return image?.jpegData(compressionQuality: 1)
    }
}
