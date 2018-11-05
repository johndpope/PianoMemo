//
//  EmojiDescriptionCell.swift
//  Piano
//
//  Created by hoemoon on 05/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class EmojiDescriptionCell: UICollectionViewCell {
    static let id = "EmojiDescriptionCell"
    @IBOutlet weak var emojiLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    var emoji: Emoji? {
        didSet {
            if let emoji = emoji {
                emojiLabel.text = emoji.string
                descriptionLabel.text = emoji.description
            }
        }
    }
}
