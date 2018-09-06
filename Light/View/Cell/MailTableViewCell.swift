//
//  MailTableViewCell.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

class MailTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var snippetLabel: UILabel!
    @IBOutlet weak var cellButton: UIButton!
    @IBOutlet weak var contentButton: UIButton!
    
    /**
     Picker용 configure.
     - parameter data : [key, value].
     */
    func configure(_ data: [String : String]?) {
        if let data = data {
            nameLabel.textColor = .black
            nameLabel.text = data["from"]
            
            subjectLabel.textColor = .black
            subjectLabel.text = data["subject"]
            
            snippetLabel.textColor = .lightGray
            snippetLabel.text = data["snippet"]
            
            dateLabel.textColor = .lightGray
            let date = (data["date"]?.dataDetector as? Date) ?? Date()
            dateLabel.text = DateFormatter.style([.short, .short]).string(from: date)
        } else {
            [nameLabel, dateLabel, subjectLabel, snippetLabel].forEach {
                $0?.textColor = .clear
                $0?.text = "text"
            }
        }
    }
    
    /**
     local용 configure.
     - parameter data : Mail managedObject.
     */
    func configure(_ mail: Mail) {
        nameLabel.textColor = .black
        nameLabel.text = mail.from
        
        subjectLabel.textColor = .black
        subjectLabel.text = mail.subject
        
        snippetLabel.textColor = .lightGray
        snippetLabel.text = mail.snippet
        
        dateLabel.textColor = .lightGray
        dateLabel.text = DateFormatter.style([.short, .short]).string(from: mail.date ?? Date())
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
