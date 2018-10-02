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
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        label.text = "형광펜 설명".loc
    }

}
