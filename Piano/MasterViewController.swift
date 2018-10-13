//
//  MasterViewController.swift
//  Piano
//
//  Created by Kevin Kim on 09/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import BiometricAuthentication
import ContactsUI

class MasterViewController: UIViewController {
    enum VCState {
        case normal
        case merge
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomView: BottomView!
    @IBOutlet var textInputView: UIView!
    
    internal var tagsCache = ""
    internal var keywordCache = ""
    weak var syncController: Synchronizable!
    
    var textAccessoryVC: TextAccessoryViewController? {
        for vc in children {
            guard let textAccessoryVC = vc as? TextAccessoryViewController else { continue }
            return textAccessoryVC
        }
        return nil
    }

    lazy var recommandOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    var collapseDetailViewController: Bool = true
    var resultsController: NSFetchedResultsController<Note> {
        return syncController.mainResultsController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setDelegate()
        syncController.setShareAcceptable(self)
//        setupDummy()
        resultsController.delegate = self
        do {
            try resultsController.performFetch()
        } catch {
            print("\(MasterViewController.self) \(#function)에서 에러")
        }
        
    }
    
    private func setupDummy() {
        for index in 1...1000000 {
            syncController.create(string: "\(index)Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus.", tags: "")
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        registerAllNotification()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        checkIfNewUser()
        deleteSelectedNoteWhenEmpty()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unRegisterAllNotification()
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? TextAccessoryViewController {
            des.setup(masterViewController: self)
            return
        }
        
        if let des = segue.destination as? UINavigationController, let vc = des.topViewController as? SettingTableViewController {
            vc.syncController = syncController
            return
        }
        
        if let des = segue.destination as? DetailViewController,
            let note = sender as? Note {
            des.note = note
            des.syncController = syncController
            return
        }
    }

}

extension MasterViewController {
    internal func setNavigationItems(state: VCState) {
        
        switch state {
        case .normal:
            let leftbtn = BarButtonItem(image: #imageLiteral(resourceName: "setting"), style: .plain, target: self, action: #selector(tapSetting(_:)))
            let rightBtn = BarButtonItem(image: #imageLiteral(resourceName: "merge"), style: .plain, target: self, action: #selector(tapMerge(_:)))
            navigationItem.setRightBarButton(rightBtn, animated: true)
            navigationItem.setLeftBarButton(leftbtn, animated: true)
        case .merge:
            let leftbtn = BarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(tapCancelMerge(_:)))
            let rightBtn = BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(tapMergeSelectedNotes(_:)))
            rightBtn.isEnabled = false
            navigationItem.setRightBarButton(rightBtn, animated: true)
            navigationItem.setLeftBarButton(leftbtn, animated: true)
        }
        
    }
    
    private func checkIfNewUser() {
        if !UserDefaults.standard.bool(forKey: UserDefaultsKey.isExistingUserKey) {
            performSegue(withIdentifier: ChecklistPickerViewController.identifier, sender: nil)
        }
    }
    
    private func deleteSelectedNoteWhenEmpty() {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: true)
            let note = resultsController.object(at: selectedIndexPath)
            if note.content?.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
                syncController.delete(note: note)
            }
        }
    }
    
    func loadNotes() {
        requestQuery()
    }
    
    private func setDelegate(){
        bottomView.masterViewController = self
        bottomView.recommandEventView.setup(viewController: self, textView: bottomView.textView)
        bottomView.recommandAddressView.setup(viewController: self, textView: bottomView.textView)
        bottomView.recommandContactView.setup(viewController: self, textView: bottomView.textView)
        bottomView.recommandReminderView.setup(viewController: self, textView: bottomView.textView)
    }
    
    // 현재 컬렉션뷰의 셀 갯수가 (fetchLimit / 0.9) 보다 큰 경우,
    // 맨 밑까지 스크롤하면 fetchLimit을 증가시킵니다.
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 0,
            scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height) {
            if tableView.numberOfRows(inSection: 0) > 90 {
                syncController.increaseFetchLimit(count: 50)
                do {
                    try resultsController.performFetch()
                    tableView.reloadData()
                } catch {
                    print(error)
                }
            }
        }
    }
}

extension MasterViewController: CLLocationManagerDelegate { }

extension MasterViewController {
    
    internal func registerAllNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    internal func unRegisterAllNotification(){
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setContentInsetForKeyboard(kbHeight: CGFloat) {
        tableView.contentInset.bottom = kbHeight + bottomView.bounds.height
        tableView.scrollIndicatorInsets.bottom = kbHeight + bottomView.bounds.height
    }
    
    internal func initialContentInset(){
        tableView.contentInset.bottom = bottomView.bounds.height
        tableView.scrollIndicatorInsets.bottom = bottomView.bounds.height
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        bottomView.keyboardToken?.invalidate()
        bottomView.keyboardToken = nil
        let mergeBtn = BarButtonItem(image: #imageLiteral(resourceName: "merge"), style: .plain, target: self, action: #selector(tapMerge(_:)))
        navigationItem.setRightBarButtonItems([mergeBtn], animated: false)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            let kbHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height
            else { return }
        
        let doneBtn = BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
        let mergeBtn = BarButtonItem(image: #imageLiteral(resourceName: "merge"), style: .plain, target: self, action: #selector(tapMerge(_:)))
        navigationItem.setRightBarButtonItems([doneBtn, mergeBtn], animated: false)
        
        bottomView.keyboardHeight = kbHeight
        textInputView.bounds.size.height = kbHeight
        bottomView.bottomViewBottomAnchor.constant = kbHeight
        setContentInsetForKeyboard(kbHeight: kbHeight)
        view.layoutIfNeeded()
        
        bottomView.keyboardToken = UIApplication.shared.windows[1].subviews.first?.subviews.first?.layer.observe(\.position, changeHandler: { [weak self](layer, change) in
            guard let `self` = self else { return }
            
            self.bottomView.bottomViewBottomAnchor.constant = max(self.view.bounds.height - layer.frame.origin.y, 0)
            self.view.layoutIfNeeded()
        })
        
    }
}

extension MasterViewController {
    
    @IBAction func tapCancelMerge(_ sender: Any) {
        
        if let selectedRow = tableView.indexPathsForSelectedRows {
            selectedRow.forEach {
                tableView.deselectRow(at: $0, animated: false)
            }
        }
        
        tableView.setEditing(false, animated: true)
        setNavigationItems(state: .normal)
    }

    @IBAction func tapMergeSelectedNotes( _ sender: Any) {
        
        
        
        if let selectedRow = tableView.indexPathsForSelectedRows {
            selectedRow.forEach {
                tableView.deselectRow(at: $0, animated: false)
            }
            
            var notesToMerge = selectedRow.map { resultsController.object(at: $0)}
            let firstNote = notesToMerge.removeFirst()
            
            let isLock = notesToMerge.first(where: { $0.isLocked })
            if let _ = isLock {
                BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
                    [weak self] in
                    // authentication success
                    guard let self = self else { return }
                    self.syncController.merge(origin: firstNote, deletes: notesToMerge)
                    self.tableView.setEditing(false, animated: true)
                    self.setNavigationItems(state: .normal)
                    self.transparentNavigationController?.show(message: "✨The notes were merged in the order you chose✨".loc, color: Color.point)
                    return
                }) { (error) in
                    Alert.warning(from: self, title: "Authentication failure😭".loc, message: "Set up passcode from the ‘settings’ to unlock this note.".loc)
                    return
                }
            } else {
                self.syncController.merge(origin: firstNote, deletes: notesToMerge)
                tableView.setEditing(false, animated: true)
                setNavigationItems(state: .normal)
                transparentNavigationController?.show(message: "✨The notes were merged in the order you chose✨".loc, color: Color.point)
            }
        }
        
    }
    

    private func setUIToNormal() {
        tableView.indexPathsForSelectedRows?.forEach {
            tableView.deselectRow(at: $0, animated: false)
        }
        tableView.setEditing(false, animated: true)
        setNavigationItems(state: .normal)
    }
    
    
    @IBAction func tapSetting(_ sender:  Any) {
        performSegue(withIdentifier: SettingTableViewController.identifier, sender: nil)
    }
    
    @IBAction func tapEraseAll(_ sender: Any) {
        tagsCache = ""
        bottomView.textView.text = ""
        bottomView.textView.typingAttributes = Preference.defaultAttr
        bottomView.textView.insertText("")
    }
    
    @IBAction func trash(_ sender: Button) {
        performSegue(withIdentifier: TrashTableViewController.identifier, sender: nil)
    }
    
    @IBAction func done(_ sender: Button) {
        bottomView.textView.resignFirstResponder()
    }
    
    @IBAction func tapMerge(_ sender: Button) {
        //테이블 뷰 edit 상태로 바꾸기
        tableView.setEditing(true, animated: true)
        setNavigationItems(state: .merge)
        transparentNavigationController?.show(message: "Please choose a memo to merge👆".loc, color: Color.point)
    }
}

extension MasterViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return resultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell") as! UITableViewCell & ViewModelAcceptable
        let note = resultsController.object(at: indexPath)
        let noteViewModel = NoteViewModel(note: note, viewController: self)
        cell.viewModel = noteViewModel
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle(rawValue: 3) ?? UITableViewCell.EditingStyle.none
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        //TODO COCOA:
        let note = resultsController.object(at: indexPath)
        let title = note.isLocked ? "🔑" : "🔒".loc
        
        let lockAction = UIContextualAction(style: .normal, title:  title, handler: {[weak self] (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            guard let self = self else { return }
            success(true)
            if note.isLocked {
                BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
                    [weak self] in
                    // authentication success
                    self?.syncController.unlockNote(note)
                    self?.transparentNavigationController?.show(message: "🔑 Unlocked✨".loc, color: Color.locked)
                    return
                }) { (error) in
                    Alert.warning(from: self, title: "Authentication failure😭".loc, message: "Set up passcode from the ‘settings’ to unlock this note.".loc)
                    return
                }
                return
            } else {
                self.syncController.lockNote(note)
                self.transparentNavigationController?.show(message: "Locked🔒".loc, color: Color.locked)
            }
        })
        //        title1Action.image
        lockAction.backgroundColor = Color.white
        
        return UISwipeActionsConfiguration(actions: [lockAction])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let note = resultsController.object(at: indexPath)
        let trashAction = UIContextualAction(style: .normal, title:  "🗑", handler: {[weak self] (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            guard let self = self else { return }
            success(true)
            
            if note.isLocked {
                BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
                    // authentication success
                    self.syncController.delete(note: note)
                    self.transparentNavigationController?.show(message: "You can restore notes in 30 days.🗑👆".loc, color: Color.trash)
                    return
                }) { (error) in
                    Alert.warning(from: self, title: "Authentication failure😭".loc, message: "Set up passcode from the ‘settings’ to unlock this note.".loc)
                    return
                }
            } else {
                self.syncController.delete(note: note)
                self.transparentNavigationController?.show(message: "You can restore notes in 30 days.🗑👆".loc, color: Color.trash)
                return
            }
            
        })
        trashAction.backgroundColor = Color.white

        
        return UISwipeActionsConfiguration(actions: [trashAction])
    }
}

extension MasterViewController: BottomViewDelegate {
    
    func bottomView(_ bottomView: BottomView, didFinishTyping attributedString: NSAttributedString) {
        // 이걸 호출해줘야 테이블뷰 업데이트 시 consistency를 유지할 수 있다.
        let tags: String
        if let title = self.title, title != "All Notes".loc {
            tags = title
        } else {
            tags = ""
        }
        syncController.create(attributedString: attributedString, tags: tags)
    }
    
    func bottomView(_ bottomView: BottomView, textViewDidChange textView: TextView) {
        
        requestQuery()
    
        perform(#selector(requestRecommand(_:)), with: textView)
    }
    
}

extension MasterViewController {
    
    @objc func requestRecommand(_ sender: Any?) {
        guard let textView = sender as? TextView else { return }
        let recommandOperation = RecommandOperation(text: textView.text, selectedRange: textView.selectedRange) { [weak self] (recommandable) in
            self?.bottomView.recommandData = recommandable
        }
        if recommandOperationQueue.operationCount > 0 {
            recommandOperationQueue.cancelAllOperations()
        }
        recommandOperationQueue.addOperation(recommandOperation)
    }
    
    
    /// persistent store에 검색 요청하는 메서드.
    /// 검색할 문자열의 길이가 30보다 작을 경우,
    /// 0.3초 이상 멈추는 경우에만 실제로 요청한다.
    ///
    /// - Parameter sender: 검색할 문자열
    
    
    func requestQuery() {
        
        let keyword = bottomView.textView.text.components(separatedBy: .whitespacesAndNewlines).first ?? ""
        //이미 모든 노트인데,
        self.title = tagsCache.count != 0 ? tagsCache : "All Notes".loc
        syncController.search(keyword: keyword, tags: tagsCache) {
            OperationQueue.main.addOperation { [weak self] in
                guard let `self` = self else { return }
                self.tableView.reloadData()
            }
        }
    }
    
    internal func showEmptyStateViewIfNeeded(count: Int){
        // emptyStateView.isHidden = count != 0
    }
}

extension MasterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !tableView.isEditing else {
            let cell = tableView.cellForRow(at: indexPath) as! NoteCell
            if let count = tableView.indexPathsForSelectedRows?.count {
                navigationItem.rightBarButtonItem?.isEnabled = count > 1
            } else {
                navigationItem.rightBarButtonItem?.isEnabled = false
            }
            
            return
        }
        self.collapseDetailViewController = false
        let note = resultsController.object(at: indexPath)
        
        if note.isLocked {
            BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
                [weak self] in
                guard let self = self else { return }
                // authentication success
                self.performSegue(withIdentifier: DetailViewController.identifier, sender: note)
                return
            }) { [weak self] (error) in
                guard let self = self else { return }
                Alert.warning(from: self, title: "Authentication failure😭".loc, message: "Set up passcode from the ‘settings’ to unlock this note.".loc)
                tableView.deselectRow(at: indexPath, animated: true)
                return
            }
        } else {
            self.performSegue(withIdentifier: DetailViewController.identifier, sender: note)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard !tableView.isEditing else {
            let cell = tableView.cellForRow(at: indexPath) as! NoteCell
            if let count = tableView.indexPathsForSelectedRows?.count {
                navigationItem.rightBarButtonItem?.isEnabled = count > 1
            } else {
                navigationItem.rightBarButtonItem?.isEnabled = false
            }
            return
        }
    }
}

extension MasterViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.sync {
            self.tableView.beginUpdates()
        }
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.sync {
            self.tableView.endUpdates()
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        DispatchQueue.main.sync {
            switch type {
            case .delete:
                guard let indexPath = indexPath else { return }
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            case .insert:
                guard let newIndexPath = newIndexPath else { return }
                self.tableView.insertRows(at: [newIndexPath], with: .automatic)
            case .update:
                guard let indexPath = indexPath,
                    let note = controller.object(at: indexPath) as? Note,
                    var cell = self.tableView.cellForRow(at: indexPath) as? UITableViewCell & ViewModelAcceptable else { return }
                cell.viewModel = NoteViewModel(note: note, viewController: self)
            case .move:
                guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
                self.tableView.moveRow(at: indexPath, to: newIndexPath)
            }

        }
    }
}
protocol ShareAcceptable: class {
    func byPassList(note: Note)
}
extension MasterViewController: ShareAcceptable {
    func byPassList(note: Note) {
        self.performSegue(withIdentifier: DetailViewController.identifier, sender: note)
    }
}

extension MasterViewController: CNContactViewControllerDelegate {
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        if contact == nil {
            //cancel
            viewController.dismiss(animated: true, completion: nil)
        } else {
            //save
            viewController.dismiss(animated: true, completion: nil)
            let message = "📍 The location is successfully registered✨".loc
            transparentNavigationController?.show(message: message, color: Color.point)
        }
    }
}
