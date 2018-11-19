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
import DifferenceKit

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
    weak var storageService: StorageService!
    lazy var backgroundQueue: OperationQueue = {
        let queue = OperationQueue()
        return queue
    }()
    var noteWrappers = [NoteWrapper]()
    var isMerging = false

    var textAccessoryVC: TextAccessoryViewController? {
        for vc in children {
            guard let textAccessoryVC = vc as? TextAccessoryViewController else { continue }
            return textAccessoryVC
        }
        return nil
    }
    static var didPerform = false
    var collapseDetailViewController: Bool = true
    var resultsController: NSFetchedResultsController<Note> {
        return storageService.local.masterResultsController
    }

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

    override func decodeRestorableState(with coder: NSCoder) {
        self.setup()
        super.decodeRestorableState(with: coder)
    }

    private func setup() {
        initialContentInset()
        setDelegate()

        resultsController.delegate = self
        requestSearch()
    }
    
    private func setupDummy() {
        for index in 1...5000 {
            storageService.local.create(string: "\(index)Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus.", tags: "", completion: nil)
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        registerAllNotification()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        deleteSelectedNoteWhenEmpty()
        byPassTableViewBug()
        storageService.remote.editingNote = nil
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unRegisterAllNotification()
        view.endEditing(true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? TextAccessoryViewController {
            des.storageService = storageService
            des.setup(masterViewController: self)
            return
        }
        
        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? SettingTableViewController {
            vc.storageService = storageService
            return
        }
        
        if let des = segue.destination as? Detail2ViewController {
            des.note = sender as? Note
            des.storageService = storageService
            return
        }
        
        if let des = segue.destination as? TransParentNavigationController,
            let vc = des.topViewController as? TagPickerViewController {
            vc.masterViewController = self
            vc.storageService = storageService
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
    
    private func deleteSelectedNoteWhenEmpty() {
        
        tableView.visibleCells.forEach {
            guard let indexPath = tableView.indexPath(for: $0) else { return }
            tableView.deselectRow(at: indexPath, animated: true)
            let note = noteWrappers[indexPath.row].note
            if note.content?.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
                storageService.local.remove(note: note) {}
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

    private func setDelegate(){
        tableView.dropDelegate = self
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
                storageService.local.refreshNoteListFetchLimit(with: 100)
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
        NotificationCenter.default.addObserver(self, selector: #selector(invalidLayout), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(byPassList(_:)), name: .bypassList, object: nil)
    }
    
    @objc func invalidLayout() {
        
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

    @objc func byPassList(_ notificaiton: Notification) {
        OperationQueue.main.addOperation { [weak self] in
            guard let self = self, let fetched = self.resultsController.fetchedObjects,
                fetched.count > 0 else { return }
            self.tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .top)
            let note = self.resultsController.object(at: IndexPath(row: 0, section: 0))
            self.performSegue(withIdentifier: Detail2ViewController.identifier, sender: note)
        }
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
        toggleSectionHeader()
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
                    self.merge(firstNote: firstNote, notesToMerge: notesToMerge)
                }) { (error) in
                    BioMetricAuthenticator.authenticateWithPasscode(reason: "", success: {
                        [weak self] in
                        // authentication success
                        guard let self = self else { return }
                        self.merge(firstNote: firstNote, notesToMerge: notesToMerge)
                    }) { (error) in
                        Alert.warning(
                            from: self,
                            title: "Authentication failure😭".loc,
                            message: "Set up passcode from the ‘settings’ to unlock this note.".loc
                        )
                        return
                    }
                }
            } else {
                merge(firstNote: firstNote, notesToMerge: notesToMerge)
            }
        }
    }
    private func merge(firstNote: Note, notesToMerge: [Note]) {
        self.storageService.local.merge(origin: firstNote, deletes: notesToMerge) { [weak self] in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.tableView.indexPathsForSelectedRows?.forEach { self.tableView.deselectRow(at: $0, animated: true)}
                self.tableView.setEditing(false, animated: true)
                let state: VCState = self.bottomView.textView.isFirstResponder ? .typing : .normal
                self.setNavigationItems(state: state)
                self.toggleSectionHeader()
                self.transparentNavigationController?.show(message: "✨The notes were merged in the order you chose✨".loc, color: Color.blueNoti)
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
    
    @IBAction func tapEraseAll(_ sender: UIButton) {
        tagsCache = ""
        bottomView.textView.text = ""
        bottomView.textView.typingAttributes = Preference.defaultAttr
        bottomView.textView.insertText("")
        textAccessoryVC?.deselectAll()
        sender.isEnabled = false
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
        toggleSectionHeader()
        
        //        transparentNavigationController?.show(message: "Select notes to merge👆".loc, color: Color.white)
    }
}

extension MasterViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return noteWrappers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell") as! UITableViewCell & ViewModelAcceptable
        let wrapped = noteWrappers[indexPath.row]
        let noteViewModel = NoteViewModel(
            note: wrapped.note,
            searchKeyword: searchKeyword,
            viewController: self
        )
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
        let note = noteWrappers[indexPath.row].note
        let title = note.isLocked ? "🔑" : "🔒".loc
        
        let lockAction = UIContextualAction(style: .normal, title:  title, handler: {[weak self] (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            guard let self = self else { return }
            success(true)
            if note.isLocked {
                BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {[weak self] in
                    // authentication success
                    self?.storageService.local.unlockNote(note) { [weak self] in
                        guard let self = self else { return }
                        DispatchQueue.main.async {
                            self.transparentNavigationController?.show(message: "🔑 Unlocked✨".loc, color: Color.yelloNoti)
                        }
                    }
                    
                    }, failure: { (error) in
                        BioMetricAuthenticator.authenticateWithPasscode(reason: "", success: {[weak self] in
                            // authentication success
                            self?.storageService.local.unlockNote(note) { [weak self] in
                                guard let self = self else { return }
                                DispatchQueue.main.async {
                                    self.transparentNavigationController?.show(message: "🔑 Unlocked✨".loc, color: Color.yelloNoti)
                                }
                            }
                            
                            }, failure: { (error) in
                                Alert.warning(from: self, title: "Authentication failure😭".loc, message: "Set up passcode from the ‘settings’ to unlock this note.".loc)
                                return
                        })
                })
            } else {
                self.storageService.local.lockNote(note) { [weak self] in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.transparentNavigationController?.show(message: "Locked🔒".loc, color: Color.goldNoti)
                    }
                }
            }
        })
        //        title1Action.image
        lockAction.backgroundColor = note.isLocked ? Color.unLocked : Color.locked
        
        return UISwipeActionsConfiguration(actions: [lockAction])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let note = noteWrappers[indexPath.row].note
        let trashAction = UIContextualAction(style: .normal, title:  "🗑", handler: {[weak self] (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            guard let self = self else { return }
            success(true)
            let message = "메모가 삭제 되었습니다."
            
            if note.isLocked {
                BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
                    // authentication success
                    self.storageService.local.remove(note: note) {}
                    self.transparentNavigationController?.show(message: message, color: Color.redNoti)
                    return
                }) { (error) in
                    BioMetricAuthenticator.authenticateWithPasscode(reason: "", success: {
                        // authentication success
                        self.storageService.local.remove(note: note) {}
                        self.transparentNavigationController?.show(message: message, color: Color.redNoti)
                        return
                    }) { (error) in
                        Alert.warning(from: self, title: "Authentication failure😭".loc, message: "Set up passcode from the ‘settings’ to unlock this note.".loc)
                        return
                    }
                }
            } else {
                self.storageService.local.remove(note: note) {}
                self.transparentNavigationController?.show(message: message, color: Color.redNoti)
                return
            }
            
        })
        trashAction.backgroundColor = Color.trash
        return UISwipeActionsConfiguration(actions: [trashAction])
    }
}

extension MasterViewController: BottomViewDelegate {
    func bottomView(_ bottomView: BottomView, moveToDetailForNewNote: Bool) {
        let tags: String
        if let title = self.title, title != "All Notes".loc {
            tags = title
        } else {
            tags = ""
        }
        
        storageService.local.create(string: "", tags: tags) { [weak self] (note) in
            guard let self = self else { return }
            self.performSegue(withIdentifier: Detail2ViewController.identifier, sender: note)
        }
    }
    
    
    func bottomView(_ bottomView: BottomView, didFinishTyping str: String) {
        let tags: String
        if let title = self.title, title != "All Notes".loc {
            tags = title
        } else {
            tags = ""
        }
        
        storageService.local.create(string: str, tags: tags)
        
    }
    
    func bottomView(_ bottomView: BottomView, textViewDidChange textView: TextView) {
        requestSearch()
        requestRecommand(textView)
    }
}

extension MasterViewController {
    private func toggleSectionHeader() {
        isMerging = !isMerging
        tableView.reloadSections(IndexSet(integer: 0), with: .fade)
    }

    var inputComponents: [String] {
        return bottomView.textView.text
            .components(separatedBy: .whitespacesAndNewlines)
    }

    var searchKeyword: String {
        return inputComponents.first ?? ""
    }

    func requestRecommand(_ textView: TextView) {
        guard let bottomView = bottomView,
            let text = textView.text else { return }
        let selectedRange = textView.selectedRange

        let paraRange = (text as NSString).paragraphRange(for: selectedRange)
        let paraStr = (text as NSString).substring(with: paraRange)

        bottomView.recommandData = paraStr.recommandData
    }
    
    func requestSearch() {
        guard searchKeyword.utf16.count < 20 else { return }
        title = tagsCache.count != 0 ? tagsCache : "All Notes".loc
        let keyword = searchKeyword

        storageService.local.filter(with: tagsCache) {
            [weak self] newNotes in
            guard let self = self else { return }
            let target = newNotes.map { NoteWrapper(note: $0, searchKeyword: keyword) }

            OperationQueue.main.addOperation { [weak self] in
                guard let self = self else { return }
                self.noteWrappers = target
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
        let note = noteWrappers[indexPath.row].note
        let identifier = Detail2ViewController.identifier
        
        if note.isLocked {
            BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
                [weak self] in
                guard let self = self else { return }
                // authentication success
                self.performSegue(withIdentifier: identifier, sender: note)
                return
            }) { [weak self] (error) in
                BioMetricAuthenticator.authenticateWithPasscode(reason: "", success: {
                    [weak self] in
                    guard let self = self else { return }
                    // authentication success
                    self.performSegue(withIdentifier: identifier, sender: note)
                    return
                }) { [weak self] (error) in
                    guard let self = self else { return }
                    Alert.warning(from: self, title: "Authentication failure😭".loc, message: "Set up passcode from the ‘settings’ to unlock this note.".loc)
                    tableView.deselectRow(at: indexPath, animated: true)
                    
                    //에러가 떠서 노트를 보여주면 안된다.
                    return
                }
            }
        } else {
            self.performSegue(withIdentifier: identifier, sender: note)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard !tableView.isEditing else {
            navigationItem.rightBarButtonItem?.isEnabled = (tableView.indexPathsForSelectedRows?.count ?? 0) > 1
            return
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableCell(withIdentifier: "HeaderCell")?.contentView
        view?.backgroundColor = UIColor.white.withAlphaComponent(0.85)
        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return isMerging ? 65.5 : 0
    }
}

extension MasterViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        OperationQueue.main.addOperation { [weak self] in
            guard let self = self else { return }
            let keyword = self.searchKeyword
            if let fetched = self.resultsController.fetchedObjects {
                let changeSet = StagedChangeset(
                    source: self.noteWrappers,
                    target: fetched.map { NoteWrapper(note: $0, searchKeyword: keyword) })

                self.tableView.reload(using: changeSet, with: .fade) { data in
                    self.noteWrappers = data
                }
            }
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {

        if let indexPath = indexPath, type == .update {
            noteWrappers[indexPath.row].setUpate()
        }

        NotificationCenter.default.post(name: .refreshTextAccessory, object: nil)
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

extension MasterViewController: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return Note.canHandle(session)
    }

    func tableView(
        _ tableView: UITableView,
        performDropWith coordinator: UITableViewDropCoordinator) {

        if let indexPath = coordinator.destinationIndexPath,
            indexPath.row < noteWrappers.count,
            let item = coordinator.items.first?.dragItem,
            let object = item.localObject as? NSString {

            var result = ""
            let note = noteWrappers[indexPath.row].note
            let tags = note.tags ?? ""

            var oldTagSet = Set(tags.splitedEmojis)
            let addedTagSet = Set(String(object).splitedEmojis)

            if oldTagSet.isSuperset(of: addedTagSet) {
                addedTagSet.forEach {
                    oldTagSet.remove($0)
                }
                result = oldTagSet.joined()
            } else {
                let filterd = String(object).splitedEmojis.filter { !tags.splitedEmojis.contains($0) }
                result = "\(filterd.joined())\(note.tags ?? "")"
            }

            storageService.local.update(note: note, tags: result) {
                DispatchQueue.main.async {
                    if let cell = tableView.cellForRow(at: indexPath) as? NoteCell,
                        let label = cell.tagsLabel {
                        let rect = cell.convert(label.bounds, from: label)
                        coordinator.drop(item, intoRowAt: indexPath, rect: rect)
                    } else {
                        coordinator.drop(item, toRowAt: indexPath)
                    }
                }
            }
        }
    }

    func tableView(
        _ tableView: UITableView,
        dropSessionDidUpdate session: UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {

        if tableView.hasActiveDrag, session.items.count > 1 {
            return UITableViewDropProposal(operation: .cancel)
        }
        return UITableViewDropProposal(operation: .copy, intent: .insertIntoDestinationIndexPath)

    }
}
