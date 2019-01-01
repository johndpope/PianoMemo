//
//  CustomizeBulletTableViewController.swift
//  Piano
//
//  Created by Kevin Kim on 14/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import StoreKit
import Reachability

class CustomizeBulletViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var accessoryToolbar: UIToolbar!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!

    var transparentView: UIView!

    var reachability: Reachability!

    override func viewDidLoad() {
        super.viewDidLoad()
        if StoreService.shared.didPurchaseListShortcutUnlocker {
            unlockListShorcut()
        }
    }

    private func setTransparentView() {
        if let window = UIApplication.shared.keyWindow {
            transparentView = UIView(frame: window.bounds)
            window.addSubview(transparentView)
            transparentView.backgroundColor = UIColor.clear
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        reachability?.stopNotifier()
    }

    private func unsetTransparentView() {
        transparentView.removeFromSuperview()
    }

    @IBAction func tapDone(_ sender: Any) {
        view.endEditing(true)
    }

    @IBAction func tapPlus(_ sender: Any) {
        addChecklistIfNeeded()
    }

    private func addChecklistIfNeeded() {
        guard !StoreService.shared.didPurchaseListShortcutUnlocker else {
            alert(
                title: "Cannot add it anymore!".loc,
                message: "You've already purchased the checklist shortcut item.".loc
            )
            return
        }

        let userDefineFormsCount = PianoBullet.userDefineForms.count
        let inviteCount = Referral.shared.inviteCount
        let requiredInviteCount: Int?
        switch userDefineFormsCount {
        case 1:
            requiredInviteCount = 1
        case 2:
            requiredInviteCount = 10
        case 3:
            requiredInviteCount = 50
        case 4:
            requiredInviteCount = 100
        default:
            requiredInviteCount = nil
        }

        guard let requiredCount = requiredInviteCount else {
            alert(
                title: "Cannot add it anymore!".loc,
                message: "Up to 5 Emoji checklists are available.".loc
            )
            return
        }

        if inviteCount >= requiredCount {
            //userDefine을 추가하는데, 기존 UserDefine과 겹치지 않게 만든다.
            addBullet()
            let indexPath = IndexPath(row: userDefineFormsCount, section: 0)
            tableView.insertRows(at: [indexPath], with: .automatic)

        } else {
            let alertController = UIAlertController(
                title: "Invite more people".loc + ": \(requiredCount - inviteCount)".loc,
                message: "Promote your piano to Internet community and your friends, and increase the number of emoji checklists!".loc,
                preferredStyle: .alert)
            let purchase = UIAlertAction(title: "Purchase".loc, style: .default) {
                [weak self] _ in
                guard let self = self else { return }
                self.processPurchase()
            }
            let cancel = UIAlertAction(title: "OK".loc, style: .default, handler: nil)
            alertController.addAction(purchase)
            alertController.addAction(cancel)
            alertController.preferredAction = cancel
            present(alertController, animated: true, completion: nil)
        }
    }

    private func addBullet() {
        var defineForms = PianoBullet.userDefineForms
        let newShortcutList = PianoBullet.shortcutList.first { (str) -> Bool in
            let shortcuts = defineForms.map { $0.shortcut }
            return !shortcuts.contains(str)
        }

        let newKeyOffList = PianoBullet.keyOffList.first { (str) -> Bool in
            let keyOffs = defineForms.map { $0.keyOff }
            return !keyOffs.contains(str)
        }

        let newKeyOnList = PianoBullet.keyOnList.first { (str) -> Bool in
            let keyOns = defineForms.map { $0.keyOn }
            return !keyOns.contains(str)
        }

        let newValueOffList = PianoBullet.valueOffList.first { (str) -> Bool in
            let valueOffs = defineForms.map { $0.valueOff }
            return !valueOffs.contains(str)
        }

        let newValueOnList = PianoBullet.valueOnList.first { (str) -> Bool in
            let valueOns = defineForms.map { $0.valueOn }
            return !valueOns.contains(str)
        }

        guard let shortcut = newShortcutList,
            let keyOff = newKeyOffList,
            let keyOn = newKeyOnList,
            let valueOff = newValueOffList,
            let valueOn = newValueOnList else { return }

        let newUserDefine = UserDefineForm(shortcut: shortcut, keyOn: keyOn, keyOff: keyOff, valueOn: valueOn, valueOff: valueOff)
        defineForms.append(newUserDefine)
        PianoBullet.userDefineForms = defineForms
    }

    func processPurchase() {
        func innerProcessPurchase() {
            guard StoreService.shared.canMakePayments() else {
                self.alert(title: "Can't proceed with this purchase".loc)
                return
            }
            activityIndicatorView.startAnimating()
            setTransparentView()
            StoreService.shared.buyListShortcutUnlocker {
                [weak self] state, error in
                guard let self = self else { return }
                switch state {
                case .purchased:
                    if StoreService.shared.didPurchaseListShortcutUnlocker {
                        self.unlockListShorcut()
                    }
                case .failed:
                    if let error = error {
                        self.alert(
                            title: "Failed Purchase.".loc,
                            message: error.localizedDescription
                        )
                    } else {
                        self.alert(title: "Failed Purchase.".loc)
                    }
                case .deferred:
                    self.alert(
                        title: "Deferred Purchase.".loc,
                        message: "Payment is waiting for approval".loc
                    )
                default:
                    break
                }
                self.activityIndicatorView.stopAnimating()
                self.unsetTransparentView()
            }
        }

        reachability = Reachability()
        reachability.whenReachable = { [weak self] _ in
            innerProcessPurchase()
            self?.reachability?.stopNotifier()
        }
        reachability.whenUnreachable = { [weak self] _ in
            self?.alert(
                title: "Network unavailable".loc,
                message: "Please connect to network and try purchase.".loc
            )
            self?.reachability?.stopNotifier()
        }
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }

    private func alert(title: String, message: String? = nil) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let action = UIAlertAction(title: "OK".loc, style: .cancel, handler: nil)
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }

    private func unlockListShorcut() {
        let maxCount = PianoBullet.shortcutList.count
        let currentCount = PianoBullet.userDefineForms.count

        for row in currentCount..<maxCount {
            self.addBullet()
            let path = IndexPath(row: row, section: 0)
            self.tableView.insertRows(at: [path], with: .automatic)
        }
    }
}

extension CustomizeBulletViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return PianoBullet.userDefineForms.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CustomizeBulletCell.reuseIdentifier, for: indexPath) as! CustomizeBulletCell

        let userDefineForm = PianoBullet.userDefineForms[indexPath.row]

        cell.userDefineForm = userDefineForm
        cell.vc = self
        cell.textField.inputAccessoryView = accessoryToolbar
        cell.emojiTextField.inputAccessoryView = accessoryToolbar

        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableCell(withIdentifier: "HeaderCell")?.contentView
        return view
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableCell(withIdentifier: "FooterCell")?.contentView
        return view
    }

}
