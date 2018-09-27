//
//  PianoGrayButton.swift
//  Piano
//
//  Created by Kevin Kim on 27/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class PianoGrayButton: UIButton {

    override var isSelected: Bool {
        didSet {
            backgroundColor = isSelected ? Color.selectedGray : Color.clear
        }
    }

}
