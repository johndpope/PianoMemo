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
        case typing
        case merge
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomView: BottomView!
    
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

    var collapseDetailViewController: Bool = true
    var resultsController: NSFetchedResultsController<Note> {
        return syncController.mainResultsController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initialContentInset()
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
            syncController.create(string: "\(index)Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus.", tags: "") {}
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
        byPassTableViewBug()
        
        selectFirstNoteIfNeeded()
        
    }
    
    private func selectFirstNoteIfNeeded() {
        //여기서 스플릿 뷰 컨트롤러의 last가 디테일이고, 현재 테이블뷰에 선택된 게 0개라면, 제일 위의 노트를 선택한다. 만약 없다면 nil을 대입한다.
        guard let detailVC = splitViewController?.viewControllers.last as? DetailViewController,
            tableView.indexPathForSelectedRow == nil else { return }
        
        
        if let _ = resultsController.fetchedObjects?.first {
            let indexPath = IndexPath(row: 0, section: 0)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
            tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
        } else {
            detailVC.note = nil
            detailVC.viewDidLoad()
        }
    }
    
    //지우거나 머지한 놈들중에 디테일 노트가 있다면, nil을 세팅해준다.
    private func resetDetailVCIfNeeded(selectedNotes: [Note]){
        guard let detailVC = splitViewController?.viewControllers.last as? DetailViewController else { return }
        let sameNote = selectedNotes.first {
            guard let note = detailVC.note else { return false }
            return $0 == note
        }
        guard sameNote != nil else { return }
        detailVC.note = nil
        detailVC.viewDidLoad()
        
    }
    
//    머지를 할 때에도
//    지울 때에도 위의 로직을 호출한다.
    
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
        
        if let des = segue.destination as? DetailViewController {
            des.note = sender as? Note
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
            navigationItem.setRightBarButtonItems([rightBtn], animated: false)
            navigationItem.setLeftBarButton(leftbtn, animated: false)
        case .merge:
            let leftbtn = BarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(tapCancelMerge(_:)))
            let rightBtn = BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(tapMergeSelectedNotes(_:)))
            rightBtn.isEnabled = (tableView.indexPathForSelectedRow?.count ?? 0) > 1
            navigationItem.setRightBarButtonItems([rightBtn], animated: false)
            navigationItem.setLeftBarButton(leftbtn, animated: false)
        case .typing:
            let doneBtn = BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
            let mergeBtn = BarButtonItem(image: #imageLiteral(resourceName: "merge"), style: .plain, target: self, action: #selector(tapMerge(_:)))
            navigationItem.setRightBarButtonItems([doneBtn, mergeBtn], animated: false)
            let leftbtn = BarButtonItem(image: #imageLiteral(resourceName: "setting"), style: .plain, target: self, action: #selector(tapSetting(_:)))
            navigationItem.setLeftBarButton(leftbtn, animated: false)
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
                syncController.remove(note: note) {}
            }
        }
    }
    
    private func byPassTableViewBug() {
        let constraint = view.constraints.first { (constraint) -> Bool in
            guard let identifier = constraint.identifier else { return false }
            return identifier == "TableView"
        }
        guard constraint == nil else { return }
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        let leadingAnchor = tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        leadingAnchor.identifier = "TableView"
        leadingAnchor.isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
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
            let numberOfRows = tableView.numberOfRows(inSection: 0)
            if Double(numberOfRows) > Double(resultsController.fetchRequest.fetchLimit) * 0.9 {
                syncController.increaseFetchLimit(count: 100)
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
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
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
    
    @objc func keyboardDidHide(_ notification: Notification) {
        initialContentInset()
        bottomView.keyboardToken?.invalidate()
        bottomView.keyboardToken = nil
        setNavigationItems(state: tableView.isEditing ? .merge : .normal)
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        initialContentInset()
        bottomView.keyboardToken?.invalidate()
        bottomView.keyboardToken = nil
        setNavigationItems(state: tableView.isEditing ? .merge : .normal)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            let kbHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height
            else { return }
        
        setNavigationItems(state: tableView.isEditing ? .merge : .typing)
        
        bottomView.keyboardHeight = kbHeight
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
        setNavigationItems(state: bottomView.textView.isFirstResponder ? .typing : .normal)
    }

    @IBAction func tapMergeSelectedNotes( _ sender: Any) {

        if let selectedRow = tableView.indexPathsForSelectedRows {
            
            var notesToMerge = selectedRow.map { resultsController.object(at: $0)}
            let firstNote = notesToMerge.removeFirst()
            
            let isLock = notesToMerge.first(where: { $0.isLocked })
            if let _ = isLock {
                BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
                    [weak self] in
                    // authentication success
                    guard let self = self else { return }
                    self.resetDetailVCIfNeeded(selectedNotes: [firstNote] + notesToMerge)
                    self.syncController.merge(origin: firstNote, deletes: notesToMerge) { [weak self] in
                        DispatchQueue.main.async {
                            guard let self = self else { return }
                            
                            self.tableView.indexPathsForSelectedRows?.forEach { self.tableView.deselectRow(at: $0, animated: true)}
                            self.tableView.setEditing(false, animated: true)
                            let state: VCState = self.bottomView.textView.isFirstResponder ? .typing : .normal
                            self.setNavigationItems(state: state)
                            self.transparentNavigationController?.show(message: "✨The notes were merged in the order you chose✨".loc, color: Color.point)
                        }
                    }
                }) { (error) in
                    Alert.warning(from: self, title: "Authentication failure😭".loc, message: "Set up passcode from the ‘settings’ to unlock this note.".loc)
                    return
                }
            } else {
                self.resetDetailVCIfNeeded(selectedNotes: [firstNote] + notesToMerge)
                self.syncController.merge(origin: firstNote, deletes: notesToMerge) { [weak self] in
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.tableView.indexPathsForSelectedRows?.forEach { self.tableView.deselectRow(at: $0, animated: true)}
                        self.tableView.setEditing(false, animated: true)
                        let state: VCState = self.bottomView.textView.isFirstResponder ? .typing : .normal
                        self.setNavigationItems(state: state)
                        self.transparentNavigationController?.show(message: "✨The notes were merged in the order you chose✨".loc, color: Color.point)
                    }
                    
                }
                
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
        transparentNavigationController?.show(message: "Select notes to merge👆".loc, color: Color.point)
    }
}

extension MasterViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = resultsController.sections {
            return sections[section].numberOfObjects
        }
        return 0
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
                    self?.syncController.unlockNote(note) { [weak self] in
                        guard let self = self else { return }
                        DispatchQueue.main.async {
                            self.transparentNavigationController?.show(message: "🔑 Unlocked✨".loc)
                        }
                    }
                }) { (error) in
                    Alert.warning(from: self, title: "Authentication failure😭".loc, message: "Set up passcode from the ‘settings’ to unlock this note.".loc)
                    return
                }
                return
            } else {
                self.syncController.lockNote(note) { [weak self] in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.transparentNavigationController?.show(message: "Locked🔒".loc, color: Color.locked)
                    }
                }
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
                    self.resetDetailVCIfNeeded(selectedNotes: [note])
                    self.syncController.remove(note: note) {}
                    self.transparentNavigationController?.show(message: "You can restore notes in 30 days.🗑👆".loc)
                    return
                }) { (error) in
                    Alert.warning(from: self, title: "Authentication failure😭".loc, message: "Set up passcode from the ‘settings’ to unlock this note.".loc)
                    return
                }
            } else {
                self.resetDetailVCIfNeeded(selectedNotes: [note])
                self.syncController.remove(note: note) {}
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
        let tags: String
        if let title = self.title, title != "All Notes".loc {
            tags = title
        } else {
            tags = ""
        }
        syncController.create(attributedString: attributedString, tags: tags) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.selectFirstNoteIfNeeded()
            }
        }
    }
    
    func bottomView(_ bottomView: BottomView, textViewDidChange textView: TextView) {
        requestQuery()
        requestRecommand(textView)
    }
    
}

extension MasterViewController {
    func requestRecommand(_ textView: TextView) {
        guard let bottomView = bottomView,
            let text = textView.text else { return }
        let selectedRange = textView.selectedRange

        let paraRange = (text as NSString).paragraphRange(for: selectedRange)
        let paraStr = (text as NSString).substring(with: paraRange)

        bottomView.recommandData = paraStr.recommandData
    }
    
    func requestQuery() {
        let keyword = bottomView.textView.text
            .components(separatedBy: .whitespacesAndNewlines).first ?? ""
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
            navigationItem.rightBarButtonItem?.isEnabled = (tableView.indexPathsForSelectedRows?.count ?? 0) > 1
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
                
                //에러가 떠서 노트를 보여주면 안된다.
                guard let _ = self.splitViewController?.viewControllers.last as? DetailViewController else { return }
                self.performSegue(withIdentifier: DetailViewController.identifier, sender: nil)
                return
            }
        } else {
            self.performSegue(withIdentifier: DetailViewController.identifier, sender: note)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard !tableView.isEditing else {
            navigationItem.rightBarButtonItem?.isEnabled = (tableView.indexPathsForSelectedRows?.count ?? 0) > 1
            return
        }
    }
}

extension MasterViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
        selectFirstNoteIfNeeded()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
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
