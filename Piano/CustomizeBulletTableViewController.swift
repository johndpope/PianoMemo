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
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 5
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CustomizeBulletCell.reuseIdentifier, for: indexPath) as! CustomizeBulletCell
        
        let userDefineForm = PianoBullet.userDefineForms.count > indexPath.row ? PianoBullet.userDefineForms[indexPath.row] : nil
        
        cell.userDefineForm = userDefineForm
        cell.vc = self
        cell.textField.inputAccessoryView = accessoryToolbar
        cell.emojiTextField.inputAccessoryView = accessoryToolbar

        return cell
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
