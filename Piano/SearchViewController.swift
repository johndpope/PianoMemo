//
//  SearchViewController.swift
//  Piano
//
//  Created by hoemoon on 19/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import BiometricAuthentication
import DifferenceKit
import CoreData

class SearchViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var bottomView: BottomView!

    @IBOutlet weak var bottomViewBottomAnchor: LayoutConstraint!

    @IBOutlet weak var clearButton: UIButton!

    @IBOutlet weak var historyTableView: UITableView!

    private var searchResults = [NoteWrapper]()

    private lazy var historyDelegate = SearchHistoryDelegate()

    weak var dataService: Writable!

    lazy var privateQueue: OperationQueue = {
        let queue = OperationQueue()
        return queue
    }()

    var keyword: String {
        return textField.text ?? ""
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
        textField.becomeFirstResponder()
        historyDelegate.searchViewController = self
        historyTableView.delegate = historyDelegate
        historyTableView.dataSource = historyDelegate
        historyTableView.tableFooterView = UIView(frame: CGRect.zero)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerAllNotification()
        refresh(with: keyword)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        EditingTracker.shared.setEditingNote(note: nil)
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func refresh(with keyword: String) {
        search(keyword: keyword) { [weak self] fetched in
            guard let self = self else { return }
            let changeSet = StagedChangeset(
                source: self.searchResults,
                target: fetched.map { NoteWrapper(note: $0, keyword: keyword) })

            let title = keyword.count != 0 ? ("Search Result".loc + ": \(fetched.count)") : "Search History".loc
            self.historyTableView.isHidden = keyword.count != 0

            if !self.historyTableView.isHidden {
                self.historyTableView.reloadData()
            }
            self.title = title

            guard changeSet.count > 0 else { return }

            self.searchResults = fetched.map { NoteWrapper(note: $0, keyword: keyword) }
            self.tableView.reloadData()
        }
    }

    private func search(keyword: String, completion: @escaping ([Note]) -> Void) {
        let search = TextSearchOperation(context: dataService.viewContext, completion: completion)
        search.setKeyword(keyword)
        privateQueue.cancelAllOperations()
        privateQueue.addOperation(search)
    }

    private func registerAllNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
        textField.addTarget(self, action: #selector(didChangeTextField), for: .editingChanged)
    }

    @objc func didChangeTextField() {
        refresh(with: keyword)
        clearButton.isEnabled = keyword.count > 0
    }

    @objc func keyboardDidHide(_ notification: Notification) {
        initialContentInset()
        bottomView.keyboardToken?.invalidate()
        bottomView.keyboardToken = nil
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        initialContentInset()
        bottomView.keyboardToken?.invalidate()
        bottomView.keyboardToken = nil
    }

    @objc func keyboardWillShow(_ notification: Notification) {

        guard let userInfo = notification.userInfo,
            let kbHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height
            else { return }

        bottomView.keyboardHeight = kbHeight
        bottomViewBottomAnchor.constant = kbHeight
        setContentInsetForKeyboard(kbHeight: kbHeight)
        view.layoutIfNeeded()

        bottomView.keyboardToken = UIApplication.shared.windows[1].subviews.first?.subviews.first?.layer.observe(\.position, changeHandler: { [weak self](layer, _) in
            guard let `self` = self else { return }

            self.bottomViewBottomAnchor.constant = max(self.view.bounds.height - layer.frame.origin.y, 0)
            self.view.layoutIfNeeded()
        })
    }

    internal func initialContentInset() {
        tableView.contentInset.bottom = bottomView.bounds.height
        tableView.scrollIndicatorInsets.bottom = bottomView.bounds.height
    }

    private func setContentInsetForKeyboard(kbHeight: CGFloat) {
        tableView.contentInset.bottom = kbHeight + bottomView.bounds.height
        tableView.scrollIndicatorInsets.bottom = kbHeight + bottomView.bounds.height
    }

    @IBAction func clearField(_ sender: UIButton) {
        textField.text = ""
        textField.sendActions(for: .editingChanged)
        historyTableView.reloadData()
    }

    @IBAction func didTapCloseButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

//    @IBAction func didTapClearButton(_ sender: UIButton) {
//        historyDelegate.clearHistory()
//    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? DetailViewController {
            des.writeService = dataService
            des.note = sender as? Note
            return
        }
    }

}

extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if var cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell") as? UITableViewCell & ViewModelAcceptable {
            let wrapped = searchResults[indexPath.row]
            let noteViewModel = NoteViewModel(
                note: wrapped.note,
                searchKeyword: keyword,
                viewController: self
            )
            cell.viewModel = noteViewModel
            return cell
        }
        return UITableViewCell()
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        historyDelegate.addHistory(keyword)
        let note = searchResults[indexPath.row].note
        let identifier = "SearchToDetail"

        if note.isLocked {
            BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
                [weak self] in
                guard let self = self else { return }
                // authentication success
                self.performSegue(withIdentifier: identifier, sender: note)
                tableView.deselectRow(at: indexPath, animated: true)
                return
            }, failure: { [weak self] error in
                BioMetricAuthenticator.authenticateWithPasscode(reason: "", success: {
                    guard let self = self else { return }
                    // authentication success
                    self.performSegue(withIdentifier: identifier, sender: note)
                    tableView.deselectRow(at: indexPath, animated: true)
                    return

                }, failure: { [weak self] error in
                    guard let self = self else { return }
                    if error == .passcodeNotSet {
                        self.performSegue(withIdentifier: identifier, sender: note)
                        tableView.deselectRow(at: indexPath, animated: true)
                        return
                    }
                    Alert.warning(
                        from: self,
                        title: "Authentication failure😭".loc,
                        message: "Set up passcode from the ‘settings’ to unlock this note.".loc
                    )
                    tableView.deselectRow(at: indexPath, animated: true)

                    //에러가 떠서 노트를 보여주면 안된다.
                    return
                })
            })
        } else {
            performSegue(withIdentifier: identifier, sender: note)
        }
    }
}
