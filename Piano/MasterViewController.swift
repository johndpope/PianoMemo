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
    }

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomView: BottomView!

    internal var tagsCache = ""
    var noteHandler: NoteHandlable?

    lazy var privateQueue: OperationQueue = {
        let queue = OperationQueue()
        return queue
    }()

    var resultsController: NSFetchedResultsController<Note>!

    var textAccessoryVC: TextAccessoryViewController? {
        for vc in children {
            guard let textAccessoryVC = vc as? TextAccessoryViewController else { continue }
            return textAccessoryVC
        }
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if noteHandler == nil {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                self.noteHandler = appDelegate.noteHandler
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
        guard let noteHandler = noteHandler else { return }
        resultsController = NSFetchedResultsController(
            fetchRequest: Note.masterRequest,
            managedObjectContext: noteHandler.context,
            sectionNameKeyPath: nil,
            cacheName: "Note"
        )

        setDelegate()
        resultsController.delegate = self
        bottomView.textView.placeholder = "Write Now".loc

//        setTableViewRefreshController()
        do {
            try noteHandler.context.setQueryGenerationFrom(NSQueryGenerationToken.current)
            try resultsController.performFetch()
            tableView.reloadData()
        } catch {
            print(error)
        }
        // 노트 갯수 로그
        if let count = resultsController.fetchedObjects?.count {
            Analytics.setUserProperty(int: count, forName: .noteTotal)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        registerAllNotification()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        byPassTableViewBug()
        EditingTracker.shared.setEditingNote(note: nil)
        deleteSelectedNoteWhenEmpty()
        initialContentInset()

        // 딥링크를 통해 앱이 실행되는 경우, textView 가 load되기 전 AppDelegate에서 호출되며 이벤트가 무시되는 것을 막기 위함
        if UserDefaults.standard.bool(forKey: "OpenQuickNote") {
            bottomView?.textView?.becomeFirstResponder()
            UserDefaults.standard.removeObject(forKey: "OpenQuickNote")
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unRegisterAllNotification()
        view.endEditing(true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? TextAccessoryViewController {
            des.setup(masterViewController: self)
            des.noteHandler = noteHandler
            return
        }

        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? SettingTableViewController {
            vc.noteHandler = noteHandler
            return
        }

        if let des = segue.destination as? DetailViewController {
            des.noteHandler = noteHandler
            des.note = sender as? Note
            return
        }

        if let des = segue.destination as? TransParentNavigationController,
            let vc = des.topViewController as? TagPickerViewController {
            vc.masterViewController = self
        }

        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? SearchViewController {
            vc.noteHandler = noteHandler
            return
        }

        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? MergeTableViewController {
            vc.masterViewController = self
            vc.noteHandler = noteHandler
            return
        }
    }

}

extension MasterViewController {
    internal func setNavigationItems(state: VCState) {

        switch state {
        case .normal:
            let leftbtn = BarButtonItem(image: #imageLiteral(resourceName: "setting"), style: .plain, target: self, action: #selector(tapSetting(_:)))
            let searchBtn = BarButtonItem(image: #imageLiteral(resourceName: "search"), style: .plain, target: self, action: #selector(tapSearch(_:)))
            let rightBtn = BarButtonItem(image: #imageLiteral(resourceName: "merge"), style: .plain, target: self, action: #selector(tapMerge(_:)))
            navigationItem.setRightBarButtonItems([rightBtn, searchBtn], animated: false)
            navigationItem.setLeftBarButton(leftbtn, animated: false)
        case .typing:
            let doneBtn = BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
            let searchBtn = BarButtonItem(image: #imageLiteral(resourceName: "search"), style: .plain, target: self, action: #selector(tapSearch(_:)))
            navigationItem.setRightBarButtonItems([doneBtn, searchBtn], animated: false)
            let leftbtn = BarButtonItem(image: #imageLiteral(resourceName: "setting"), style: .plain, target: self, action: #selector(tapSetting(_:)))
            navigationItem.setLeftBarButton(leftbtn, animated: false)
        }

    }

    private func deleteSelectedNoteWhenEmpty() {
        tableView.visibleCells.forEach {
            guard let indexPath = tableView.indexPath(for: $0),
                let noteHandler = noteHandler else { return }
            tableView.deselectRow(at: indexPath, animated: true)
            let note = resultsController.object(at: indexPath)
            if note.content?.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
                noteHandler.purge(notes: [note])
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

    private func setDelegate() {
        tableView.dropDelegate = self
        bottomView.masterViewController = self
        bottomView.recommandEventView.setup(viewController: self, textView: bottomView.textView)
        bottomView.recommandAddressView.setup(viewController: self, textView: bottomView.textView)
        bottomView.recommandContactView.setup(viewController: self, textView: bottomView.textView)
        bottomView.recommandReminderView.setup(viewController: self, textView: bottomView.textView)
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
        NotificationCenter.default.addObserver(self, selector: #selector(notifyError(_:)), name: .displayCKErrorMessage, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(doneRefreshTableView), name: .didFinishHandleZoneChange, object: nil)
    }

    @objc func notifyError(_ notification: Notification) {
        guard let message = notification.userInfo?["message"] as? String else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.transparentNavigationController?
                .show(message: message, color: Color.redNoti)
        }
    }

    @objc func invalidLayout() {

    }

    internal func unRegisterAllNotification() {
        NotificationCenter.default.removeObserver(self)
    }

    private func setContentInsetForKeyboard(kbHeight: CGFloat) {
        tableView.contentInset.bottom = kbHeight + bottomView.bounds.height
        tableView.scrollIndicatorInsets.bottom = kbHeight + bottomView.bounds.height
    }

    internal func initialContentInset() {
        tableView.contentInset.bottom = bottomView.bounds.height
        tableView.scrollIndicatorInsets.bottom = bottomView.bounds.height
    }

    @objc func keyboardDidHide(_ notification: Notification) {
        initialContentInset()
        bottomView.keyboardToken?.invalidate()
        bottomView.keyboardToken = nil
        setNavigationItems(state: .normal)
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        initialContentInset()
        bottomView.keyboardToken?.invalidate()
        bottomView.keyboardToken = nil
        setNavigationItems(state: .normal)
    }

    @objc func keyboardWillShow(_ notification: Notification) {

        guard let userInfo = notification.userInfo,
            let kbHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height
            else { return }

        setNavigationItems(state: .typing)

        bottomView.keyboardHeight = kbHeight
        bottomView.bottomViewBottomAnchor.constant = kbHeight
        setContentInsetForKeyboard(kbHeight: kbHeight)
        view.layoutIfNeeded()

        bottomView.keyboardToken = UIApplication.shared.windows[1].subviews.first?.subviews.first?.layer.observe(\.position, changeHandler: { [weak self](layer, _) in
            guard let `self` = self else { return }

            self.bottomView.bottomViewBottomAnchor.constant = max(self.view.bounds.height - layer.frame.origin.y, 0)
            self.view.layoutIfNeeded()
        })
    }

    @objc func byPassList(_ notificaiton: Notification) {
        OperationQueue.main.addOperation { [weak self] in
            guard let self = self,
                let fetched = self.resultsController.fetchedObjects,
                fetched.count > 0 else { return }

            self.tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .top)
            let note = self.resultsController.object(at: IndexPath(row: 0, section: 0))
            self.performSegue(withIdentifier: DetailViewController.identifier, sender: note)
        }
    }
}

extension MasterViewController {
    private func setTableViewRefreshController() {
        let refreshController = UIRefreshControl()
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor(white: 0, alpha: 0.5)]
        refreshController.attributedTitle = NSAttributedString(string: "Sync in a wink".loc, attributes: attrs)
        refreshController.addTarget(self, action: #selector(refreshTableView(_:)), for: .valueChanged)
        tableView.refreshControl = refreshController
    }

    private func setUIToNormal() {
        tableView.indexPathsForSelectedRows?.forEach {
            tableView.deselectRow(at: $0, animated: false)
        }
        tableView.setEditing(false, animated: true)
        setNavigationItems(state: .normal)
    }

    @IBAction func tapSetting(_ sender: Any) {
        performSegue(withIdentifier: SettingTableViewController.identifier, sender: nil)
    }

    @IBAction func tapSearch(_ sender: Any) {
        performSegue(withIdentifier: SearchViewController.identifier, sender: nil)
    }

    @IBAction func tapEraseAll(_ sender: UIButton) {
        tagsCache = ""
        bottomView.textView.text = ""
        bottomView.textView.typingAttributes = Preference.defaultAttr
        bottomView.textView.insertText("")
        textAccessoryVC?.deselectAll()
        sender.isEnabled = false
        requestFilter()
    }

    @IBAction func trash(_ sender: Button) {
        performSegue(withIdentifier: TrashTableViewController.identifier, sender: nil)
    }

    @IBAction func done(_ sender: Button) {
        bottomView.textView.resignFirstResponder()
    }

    @IBAction func tapMerge(_ sender: Button) {
        performSegue(withIdentifier: MergeTableViewController.identifier, sender: nil)
    }

    @IBAction func refreshTableView(_ sender: Any) {
        NotificationCenter.default.post(name: .fetchDataFromRemote, object: nil)
    }

    @IBAction func doneRefreshTableView() {
        DispatchQueue.main.async {
            self.tableView.refreshControl?.endRefreshing()
        }
    }
}

extension MasterViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return resultsController.sections?.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = resultsController.sections?[section] else {
            return 0
        }
        return sectionInfo.numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell") as! UITableViewCell & ViewModelAcceptable
        let note = resultsController.object(at: indexPath)
        let noteViewModel = NoteViewModel(
            note: note,
            viewController: self
        )
        cell.viewModel = noteViewModel
        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !tableView.isEditing
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle(rawValue: 3) ?? UITableViewCell.EditingStyle.none
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let note = resultsController.object(at: indexPath)
        let title = note.isPinned == 1 ? "↩️" : "📌"

        let pinAction = UIContextualAction(style: .normal, title: title) { [weak self] _, _, actionPerformed in
            guard let self = self, let noteHandler = self.noteHandler else { return }
            if note.isPinned == 1 {
                noteHandler.unPinNote(notes: [note]) { _ in
                    actionPerformed(true)
                }
            } else {
                noteHandler.pinNote(notes: [note]) { _ in
                    actionPerformed(true)
                }
            }
        }

        pinAction.backgroundColor = note.isPinned == 1 ?
            UIColor(red: 0.62, green: 0.70, blue: 0.78, alpha: 1.00) :
            UIColor(red: 0.88, green: 0.51, blue: 0.51, alpha: 1.00)

        return UISwipeActionsConfiguration(actions: [pinAction])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        func performRemove(note: Note) {
            guard let noteHandler = noteHandler else { return }
            Analytics.deleteNoteAt = "homeTable"
            let message = "Note are deleted.".loc
            noteHandler.remove(notes: [note]) { [weak self] in
                guard let self = self else { return }
                if $0 {
                    self.transparentNavigationController?.show(message: message, color: Color.redNoti)
                }
            }
        }

        func toggleLock(note: Note, setLock: Bool) {
            guard let noteHandler = noteHandler else { return }
            if setLock {
                noteHandler.lockNote(notes: [note]) { [weak self] in
                    guard let self = self else { return }
                    if $0 {
                        self.transparentNavigationController?.show(message: "Locked🔒".loc, color: Color.goldNoti)
                    }
                }
            } else {
                noteHandler.unlockNote(notes: [note]) { [weak self] in
                    guard let self = self else { return }
                    if $0 {
                        self.transparentNavigationController?.show(message: "🔑 Unlocked✨".loc, color: Color.yelloNoti)
                    }
                }
            }
        }

        let note = resultsController.object(at: indexPath)
        let trashAction = UIContextualAction(style: .normal, title: "🗑") { [weak self] _, _, completion in
            guard let self = self else { return }
            completion(true)
            if note.hasLockTag {
                BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
                    performRemove(note: note)
                }, failure: { _ in
                    BioMetricAuthenticator.authenticateWithPasscode(reason: "", success: {
                        performRemove(note: note)
                    }, failure: {
                        if $0 == .passcodeNotSet {
                            performRemove(note: note)
                            return
                        }
                        Alert.warning(
                            from: self,
                            title: "Authentication failure😭".loc,
                            message: "Set up passcode from the ‘settings’ to unlock this note.".loc
                        )
                    })
                })
            } else {
                performRemove(note: note)
            }
        }

        let title = note.hasLockTag ? "🔑" : "🔒"

        let lockAction = UIContextualAction(style: .normal, title: title) { _, _, completion in
            completion(true)
            if note.hasLockTag {
                BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
                    toggleLock(note: note, setLock: false)
                }, failure: { _ in
                    BioMetricAuthenticator.authenticateWithPasscode(reason: "", success: {
                        // authentication success
                        toggleLock(note: note, setLock: false)

                    }, failure: {
                        if $0 == .passcodeNotSet {
                            toggleLock(note: note, setLock: false)
                            return
                        }
                        Alert.warning(
                            from: self,
                            title: "Authentication failure😭".loc,
                            message: "Set up passcode from the ‘settings’ to unlock this note.".loc
                        )
                    })
                })
            } else {
                toggleLock(note: note, setLock: true)
            }
        }

        trashAction.backgroundColor = UIColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 1.00)
        lockAction.backgroundColor = note.hasLockTag ?
            UIColor(red: 1.00, green: 0.92, blue: 0.37, alpha: 1.00) :
            UIColor(red: 0.82, green: 0.80, blue: 0.58, alpha: 1.00)
        return UISwipeActionsConfiguration(actions: [trashAction, lockAction])
    }
}

extension MasterViewController: BottomViewDelegate {
    func bottomView(_ bottomView: BottomView, moveToDetailForNewNote: Bool) {
        guard let noteHandler = noteHandler else { return }
        let tags: String
        if let title = self.title, title != "All Notes".loc {
            tags = title
        } else {
            tags = ""
        }

        noteHandler.create(content: "", tags: tags, needUpload: false) { note in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.performSegue(withIdentifier: DetailViewController.identifier, sender: note)
            }
        }
    }

    func bottomView(_ bottomView: BottomView, didFinishTyping str: String) {
        guard let noteHandler = noteHandler else { return }
        let tags: String
        if let title = self.title, title != "All Notes".loc {
            tags = title
        } else {
            tags = ""
        }
        noteHandler.create(content: str, tags: tags)
    }

    func bottomView(_ bottomView: BottomView, textViewDidChange textView: TextView) {
        requestRecommand(textView)
    }
}

extension MasterViewController {
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

    func requestFilter() {
        guard let noteHandler = noteHandler else { return }
        title = tagsCache.count != 0 ? tagsCache : "All Notes".loc

        let filter = FilterNoteOperation(context: noteHandler.context, controller: resultsController) { [weak self] in
            guard let self = self else { return }
            self.tableView.reloadData()
            if self.tableView.numberOfRows(inSection: 0) > 0 {
                self.tableView.scrollToRow(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
            }
        }
        filter.setTags(tagsCache)
        OperationQueue.main.addOperation(filter)
    }

    internal func showEmptyStateViewIfNeeded(count: Int) {
        // emptyStateView.isHidden = count != 0
    }
}

extension MasterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        func localPerformSegue(_ note: Note) {
            let identifier = DetailViewController.identifier
            performSegue(withIdentifier: identifier, sender: note)
        }
        guard !tableView.isEditing else {
            navigationItem.rightBarButtonItem?.isEnabled = (tableView.indexPathsForSelectedRows?.count ?? 0) > 1
            return
        }
        let note = resultsController.object(at: indexPath)

        if note.hasLockTag {
            BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
                localPerformSegue(note)
            }, failure: { _ in
                BioMetricAuthenticator.authenticateWithPasscode(reason: "", success: {
                    localPerformSegue(note)
                }, failure: {
                    if $0 == .passcodeNotSet {
                        localPerformSegue(note)
                        tableView.deselectRow(at: indexPath, animated: true)
                        return
                    }

                    Alert.warning(
                        from: self,
                        title: "Authentication failure😭".loc,
                        message: "Set up passcode from the ‘settings’ to unlock this note.".loc
                    )
                    tableView.deselectRow(at: indexPath, animated: true)
                })
            })
        } else {
            localPerformSegue(note)
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
        tableView.beginUpdates()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {

        switch type {
        case .delete:
            guard let indexPath = indexPath else { return }
            self.tableView.deleteRows(at: [indexPath], with: .automatic)

        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            self.tableView.insertRows(at: [newIndexPath], with: .automatic)

        case .update:
            if let indexPath = indexPath,
                let note = controller.object(at: indexPath) as? Note,
                let cell = self.tableView.cellForRow(at: indexPath) as? NoteCell {
                cell.viewModel = NoteViewModel(note: note, viewController: self)
            }
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            self.tableView.insertRows(at: [newIndexPath], with: .automatic)
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
            let message = "📍 The location is successfully registered in Contacts✨".loc
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
            let notes = resultsController.fetchedObjects,
            indexPath.row < notes.count,
            let item = coordinator.items.first?.dragItem,
            let object = item.localObject as? NSString {

            func update(_ note: Note) {
                guard let noteHandler = noteHandler else { return }
                var result = ""
                let tags = note.tags ?? ""
                var oldTagSet = Set(tags.splitedEmojis)
                let addedTagSet = Set(String(object).splitedEmojis)

                if oldTagSet.isSuperset(of: addedTagSet) {
                    addedTagSet.forEach {
                        oldTagSet.remove($0)
                    }
                    result = oldTagSet.joined()
                } else {
                    let filterd = String(object).splitedEmojis
                        .filter { !tags.splitedEmojis.contains($0) }
                    result = "\(filterd.joined())\(note.tags ?? "")"
                }
                noteHandler.updateTag(tags: result, note: note) { _ in
                    if let cell = tableView.cellForRow(at: indexPath) as? NoteCell,
                        let label = cell.tagsLabel {
                        let rect = cell.convert(label.bounds, from: label)
                        coordinator.drop(item, intoRowAt: indexPath, rect: rect)
                    } else {
                        coordinator.drop(item, toRowAt: indexPath)
                    }
                }
            }

            let note = resultsController.object(at: indexPath)

            if note.hasLockTag {
                BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
                    // authentication success
                    update(note)

                    }, failure: { (error) in
                        BioMetricAuthenticator.authenticateWithPasscode(reason: "", success: {
                            // authentication success
                            update(note)

                            }, failure: {[weak self] (error) in
                                guard let self = self else { return }
                                switch error {
                                case .passcodeNotSet:
                                    // authentication success
                                    update(note)
                                    return
                                default:
                                    ()
                                }
                                Alert.warning(from: self, title: "Authentication failure😭".loc, message: "Set up passcode from the ‘settings’ to unlock this note.".loc)
                                return
                        })
                })
            } else {
                update(note)
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
