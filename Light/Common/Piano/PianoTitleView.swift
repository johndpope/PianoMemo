//
//  PianoTitleView.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 4..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

class PianoTitleView: UIView {

    @IBOutlet weak var label: UILabel!
    
    internal func set(text: String) {
        label.text = text
    }

}
