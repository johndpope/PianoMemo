//
//  SearchHistoryCell.swift
//  Piano
//
//  Created by hoemoon on 20/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class SearchHistoryCell: UITableViewCell {
    static let id = "SearchHistoryCell"

    @IBOutlet weak var label: UILabel!

    var history: String = "" {
        willSet {
            label.text = newValue
        }
    }
}
