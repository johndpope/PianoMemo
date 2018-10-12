//
//  PianoButton.swift
//  Piano
//
//  Created by Kevin Kim on 18/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class PianoButton: UIButton {
    
    override var isSelected: Bool {
        didSet {
            backgroundColor = isSelected ? Color.selected : Color.clear
        }
    }

}
