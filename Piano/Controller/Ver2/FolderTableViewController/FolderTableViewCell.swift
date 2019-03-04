//
//  FolderTableViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 26/02/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class FolderTableViewCell: UITableViewCell {

    @IBOutlet weak var emojiLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
