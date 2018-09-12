//
//  SettingTableViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 6..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

class SettingTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()


    }


    enum Action: Int {
        case allow = 0
        case emojiOption = 1
        case ratePiano = 2
        case pianoWebsite = 3
        case facebook = 4
        case support = 5
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let action = Action(rawValue: indexPath.row) else { return }
        
        switch action {
        case .allow:
            ()
        case .emojiOption:
            ()
        case .ratePiano:
            ()
        case .pianoWebsite:
            ()
        case .facebook:
            ()
        case .support:
            ()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

extension SettingTableViewController {
    @IBAction func cancel(){
        dismiss(animated: true, completion: nil)
    }
}