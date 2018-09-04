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
    
    func configure(_ data: [String : String]?) {
        reset()
        if let data = data {
            nameLabel.textColor = .black
            dateLabel.textColor = .lightGray
            subjectLabel.textColor = .black
            snippetLabel.textColor = .lightGray
            
            nameLabel.text = data["from"]
            dateLabel.text = data["date"]
            subjectLabel.text = data["subject"]
            snippetLabel.text = data["snippet"]
        }
    }
    
    private func reset() {
        [nameLabel, dateLabel, subjectLabel, snippetLabel].forEach {
            $0!.textColor = .clear
            $0!.text = ($0 == snippetLabel) ? "text\ntext" : "text"
        }
    }
    
}
