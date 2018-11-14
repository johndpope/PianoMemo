//
//  CustomizeBulletTableViewController.swift
//  Piano
//
//  Created by Kevin Kim on 14/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class CustomizeBulletTableViewController: UITableViewController {
    
    @IBOutlet var accessoryToolbar: UIToolbar!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    @IBAction func tapDone(_ sender: Any) {
        view.endEditing(true)
    }
    
    @IBAction func tapPlus(_ sender: Any) {
        var userDefineForms = PianoBullet.userDefineForms
        guard userDefineForms.count < 10 else {
            (navigationController as? TransParentNavigationController)?.show(message: "최대 10개까지 등록이 가능합니다.".loc, color: Color.redNoti)
            return
        }
        
        let keyOff = PianoBullet.keyOffList.first { keyOff in
            return !userDefineForms.contains(where: { (userDefineForm) -> Bool in
                return userDefineForm.keyOff == keyOff
            })
        }
        
        guard let keyOffStr = keyOff else { return }
        
        let keyOn = PianoBullet.keyOnList.first { keyOn in
            return !userDefineForms.contains(where: { (userDefineForm) -> Bool in
                return userDefineForm.keyOn == keyOn || keyOn == keyOffStr
            })
        }
        
        guard let keyOnStr = keyOn else { return }
        
        let valueOn = PianoBullet.valueList.first { valueOn in
            return !userDefineForms.contains(where: { (userDefineForm) -> Bool in
                return userDefineForm.valueOn == valueOn || userDefineForm.valueOff == valueOn
            })
        }
        
        guard let valueOnStr = valueOn else { return }
        
        let valueOff = PianoBullet.valueList.first { (valueOff) -> Bool in
            return !userDefineForms.contains(where: { (userDefineForm) -> Bool in
                return userDefineForm.valueOff == valueOff || valueOff == valueOnStr || userDefineForm.valueOn == valueOff
            })
        }
        
        guard let valueOffStr = valueOff else { return }
        
        let userDefineForm = UserDefineForm(keyOn: keyOnStr, keyOff: keyOffStr, valueOn: valueOnStr, valueOff: valueOffStr)
        userDefineForms.append(userDefineForm)
        PianoBullet.userDefineForms = userDefineForms
        
        let newIndexPath = IndexPath(row: tableView.numberOfRows(inSection: 0), section: 0)
        tableView.insertRows(at: [newIndexPath], with: .automatic)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return [PianoBullet.userDefineForms].count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return [PianoBullet.userDefineForms][section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CustomizeBulletCell.reuseIdentifier, for: indexPath) as! CustomizeBulletCell
        let userDefineForm = [PianoBullet.userDefineForms][indexPath.section][indexPath.row]
        cell.userDefineForm = userDefineForm
        cell.vc = self
        cell.textField.inputAccessoryView = accessoryToolbar

        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .normal, title:  "", handler: {(ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            success(true)
            //[PianoBullet.userDefineForms]에서 해당 인덱스를 리무브시켜서 다시 세팅한다
            var userDefineForms = PianoBullet.userDefineForms
            userDefineForms.remove(at: indexPath.row)
            PianoBullet.userDefineForms = userDefineForms
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            
        })
        delete.backgroundColor = Color.red
        delete.image = #imageLiteral(resourceName: "Trash Icon")
        return UISwipeActionsConfiguration(actions: [delete])
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableCell(withIdentifier: "HeaderCell")?.contentView
        return view
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableCell(withIdentifier: "FooterCell")?.contentView
        return view
    }
    
    
 


}
