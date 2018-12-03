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
            requiredInviteCount = 100
        case 4:
            requiredInviteCount = 1000
        default:
            requiredInviteCount = nil
        }
        
        guard let requiredCount = requiredInviteCount else {
            let alertController = UIAlertController(title: "더이상 추가할 수 없어요!".loc, message: "이모지 체크리스트는 최대 5개까지 사용가능합니다.".loc, preferredStyle: .alert)
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
            let alertController = UIAlertController(title: "초대 사용자 수 \(requiredCount - inviteCount)명 부족".loc, message: "인터넷 커뮤니티, 친구들에게 피아노를 홍보하여 이모지 체크리스트 갯수를 늘려보세요!".loc, preferredStyle: .alert)
            let action = UIAlertAction(title: "OK".loc, style: .cancel, handler: nil)
            alertController.addAction(action)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    
    // MARK: - Table view data source

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
