//
//  ContactTableViewCell.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import Contacts

class ContactTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    
    func configure(_ contact: CNContact) {
        nameLabel.text = contact.familyName + " " + contact.givenName
    }

}
