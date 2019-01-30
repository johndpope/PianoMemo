//
//  BlockTVCell_action.swift
//  Piano
//
//  Created by Kevin Kim on 22/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension BlockTableViewCell {
    @IBAction func tapFormButton(_ sender: Button) {
        Feedback.success()
        toggleCheckIfNeeded(button: sender)
    }
}
