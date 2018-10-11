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

protocol TextViewType {
    var textViewRef: TextView { get }
}

class MasterViewController: UIViewController, TextViewType {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomView: BottomView!
    @IBOutlet var textInputView: UIView!
    
    internal var inputTextCache = ""
    weak var syncController: Synchronizable!
    var textViewRef: TextView { return bottomView.textView }
    
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
        resultsController.delegate = self
        do {
            try resultsController.performFetch()
        } catch {
            print("\(MasterViewController.self) \(#function)에서 에러")
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        registerAllNotification()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkIfNewUser()
        deleteSelectedNoteWhenEmpty()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unRegisterAllNotification()
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //TODO COCOA:
        if let des = segue.destination as? TextAccessoryViewController {
            des.setup(textView: bottomView.textView, viewController: self)
            return
        }
        
        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? DetailViewController,
            let selectedIndexPath = tableView.indexPathForSelectedRow {
            vc.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            vc.navigationItem.leftItemsSupplementBackButton = true
            let note = resultsController.object(at: selectedIndexPath)
            vc.note = note
            vc.syncController = syncController
            return
        }
        
        if let des = segue.destination as? DetailViewController,
            let note = sender as? Note {
            des.note = note
            des.syncController = syncController
            return
        }
        
        if let des = segue.destination as? UINavigationController, let vc = des.topViewController as? TrashTableViewController {
            vc.syncController = syncController
            return
        }
        
        if let des = segue.destination as? UINavigationController, let vc = des.topViewController as? MergeTableViewController {
            vc.syncController = syncController
        }
    }

}

extension MasterViewController {
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
        requestQuery("")
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
        
        let trashBtn = BarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(trash(_:)))
        navigationItem.setRightBarButton(trashBtn, animated: false)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            let kbHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height
            else { return }
        
        let doneBtn = BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
        navigationItem.setRightBarButton(doneBtn, animated: false)
        
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
    
    @IBAction func switchKeyboard(_ sender: Button) {
        sender.isSelected = !sender.isSelected
        
        if sender.isSelected {
            //인풋 뷰 대입하기
            if !textViewRef.isFirstResponder {
                textViewRef.becomeFirstResponder()
            }
            textViewRef.inputView = textInputView
            textViewRef.reloadInputViews()
            
        } else {
            //TODO: 위에 테이블 뷰 메모로 리셋
            //키보드 리셋시키기
            textViewRef.inputView = nil
            textViewRef.reloadInputViews()
        }
    }
    
    @IBAction func trash(_ sender: Button) {
        performSegue(withIdentifier: TrashTableViewController.identifier, sender: nil)
    }
    
    @IBAction func done(_ sender: Button) {
        bottomView.textView.resignFirstResponder()
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
                    self?.transparentNavigationController?.show(message: "🔑 Unlocked✨".loc)
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
        //TODO COCOA:
        
        let note = resultsController.object(at: indexPath)
        let trashAction = UIContextualAction(style: .normal, title:  "🗑", handler: {[weak self] (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            guard let self = self else { return }
            success(true)
            
            if note.isLocked {
                BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
                    // authentication success
                    self.syncController.delete(note: note)
                    self.transparentNavigationController?.show(message: "You can restore notes in 30 days.🗑👆".loc)
                    return
                }) { (error) in
                    Alert.warning(from: self, title: "Authentication failure😭".loc, message: "Set up passcode from the ‘settings’ to unlock this note.".loc)
                    return
                }
            } else {
                self.syncController.delete(note: note)
                self.transparentNavigationController?.show(message: "You can restore notes in 30 days.🗑👆".loc)
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
        syncController.create(with: attributedString)
    }
    
    func bottomView(_ bottomView: BottomView, textViewDidChange textView: TextView) {
        
        if let firstStr = textView.text.components(separatedBy: .whitespacesAndNewlines).first, inputTextCache != firstStr {
            perform(#selector(requestQuery(_:)), with: firstStr)
            inputTextCache = firstStr
        }
        
        
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
    @objc func requestQuery(_ sender: Any?) {
        guard let text = sender as? String,
            text.count < 30  else { return }
        
        syncController.search(with: text) { notes in
            OperationQueue.main.addOperation { [weak self] in
                guard let `self` = self else { return }
                let cache = self.inputTextCache
                self.title = cache.count != 0 ? cache : "모든메모"
                
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
        self.collapseDetailViewController = false
        let note = resultsController.object(at: indexPath)
        
        if note.isLocked {
            BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
                [weak self] in
                guard let self = self else { return }
                // authentication success
                self.performSegue(withIdentifier: DetailViewController.identifier, sender: nil)
                return
            }) { [weak self] (error) in
                guard let self = self else { return }
                Alert.warning(from: self, title: "Authentication failure😭".loc, message: "Set up passcode from the ‘settings’ to unlock this note.".loc)
                tableView.deselectRow(at: indexPath, animated: true)
                return
            }
        } else {
            self.performSegue(withIdentifier: DetailViewController.identifier, sender: nil)
        }
    }
}

extension MasterViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.sync { [weak self] in
            self?.tableView.beginUpdates()
        }
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.sync { [weak self] in
            self?.tableView.endUpdates()
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
