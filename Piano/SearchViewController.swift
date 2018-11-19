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

class SearchViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var bottomView: BottomView!

    @IBOutlet weak var bottomViewBottomAnchor: LayoutConstraint!

    @IBOutlet weak var clearButton: UIButton!

    weak var storageService: StorageService!

    private var searchResults = [NoteWrapper]()

    var keyword: String {
        return textField.text ?? ""
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerAllNotification()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textField.becomeFirstResponder()
    }

    private func refresh(with keyword: String) {
        storageService.local.search(keyword: keyword) {
            [weak self] fetched in
            guard let self = self else { return }
            let changeSet = StagedChangeset(
                source: self.searchResults,
                target: fetched.map { NoteWrapper(note: $0, keyword: keyword) })

            self.title = "검색결과 \(fetched.count)개"

            self.tableView.reload(using: changeSet, with: .fade) {
                [weak self] in
                guard let self = self else { return }
                self.searchResults = $0
            }
        }
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

        bottomView.keyboardToken = UIApplication.shared.windows[1].subviews.first?.subviews.first?.layer.observe(\.position, changeHandler: { [weak self](layer, change) in
            guard let `self` = self else { return }

            self.bottomViewBottomAnchor.constant = max(self.view.bounds.height - layer.frame.origin.y, 0)
            self.view.layoutIfNeeded()
        })
    }

    internal func initialContentInset(){
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
    }

    @IBAction func didTapCloseButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? Detail2ViewController {
            des.note = sender as? Note
            des.storageService = storageService
            return
        }
    }

}

extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell") as! UITableViewCell & ViewModelAcceptable
        let wrapped = searchResults[indexPath.row]
        let noteViewModel = NoteViewModel(
            note: wrapped.note,
            searchKeyword: keyword,
            viewController: self
        )
        cell.viewModel = noteViewModel
        return cell
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let note = searchResults[indexPath.row].note
        let identifier = "SearchToDetail"

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
            performSegue(withIdentifier: identifier, sender: note)
        }
    }
}

