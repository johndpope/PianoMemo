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
    @IBOutlet weak var cellButton: UIButton!
    @IBOutlet weak var contentButton: UIButton!
    
    func configure(_ contact: CNContact, isLinked: Bool? = nil) {
        nameLabel.text = contact.familyName + " " + contact.givenName
        guard let isLinked = isLinked else {return}
        alpha = isLinked ? 0.3 : 1
    }
    
    var cellDidSelected: (() -> ())?
    @IBAction private func action(cell: UIButton) {
        cellDidSelected?()
    }
    
    var contentDidSelected: (() -> ())?
    @IBAction private func action(content: UIButton) {
        contentDidSelected?()
    }

}
