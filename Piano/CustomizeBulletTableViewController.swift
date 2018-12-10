//
//  CustomizeBulletTableViewController.swift
//  Piano
//
//  Created by Kevin Kim on 14/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class CustomizeBulletViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var accessoryToolbar: UIToolbar!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func tapDone(_ sender: Any) {
        view.endEditing(true)
    }
    
    @IBAction func tapPlus(_ sender: Any) {
        AddChecklistIfNeeded()

    }
    
    
    private func AddChecklistIfNeeded() {
        let userDefineFormsCount = PianoBullet.userDefineForms.count
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
            let alertController = UIAlertController(title: "Cannot add it anymore!".loc, message: "Up to 5 Emoji checklists are available.".loc, preferredStyle: .alert)
            let action = UIAlertAction(title: "OK".loc, style: .cancel, handler: nil)
            alertController.addAction(action)
            present(alertController, animated: true, completion: nil)
            return
        }
        
        let inviteCount = Referral.shared.inviteCount
        if inviteCount >= requiredCount {
            //userDefine을 추가하는데, 기존 UserDefine과 겹치지 않게 만든다.
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
            let indexPath = IndexPath(row: userDefineFormsCount, section: 0)
            tableView.insertRows(at: [indexPath], with: .automatic)
            
        } else {
            let alertController = UIAlertController(title: "Invite more people".loc + ": \(requiredCount - inviteCount)".loc, message: "Promote your piano to Internet community and your friends, and increase the number of emoji checklists!".loc, preferredStyle: .alert)
            let purchase = UIAlertAction(title: "Purchase", style: .default) {
                [weak self] action in
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

    func processPurchase() {
        StoreService.shared.buyProduct(formsCount: PianoBullet.userDefineForms.count)
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
