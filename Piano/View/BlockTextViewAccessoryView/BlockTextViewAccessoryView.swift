//
//  BlockTextViewAccessoryView.swift
//  Piano
//
//  Created by Kevin Kim on 01/02/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class BlockTextViewAccessoryView: UIView {

    @IBOutlet weak var recommandView: UIView!
    @IBOutlet weak var registerBtn: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var dDayLabel: UILabel!
    weak var textView: BlockTextView?

    @IBAction func tapUndo(_ sender: UIButton) {
        recommandView.isHidden = false
    }
    
    @IBAction func tapRegister(_ sender: UIButton) {
        recommandView.isHidden = true
    }

    @IBAction func tapDone(_ sender: UIButton) {
        textView?.resignFirstResponder()
    }

}
