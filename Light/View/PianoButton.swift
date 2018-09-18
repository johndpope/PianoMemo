//
//  PianoButton.swift
//  Piano
//
//  Created by Kevin Kim on 18/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class PianoButton: UIButton {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        if isSelected {
            self.cornerRadius = bounds.height / 2
            self.borderWidth = 2
            self.borderColor = Color(red: 62/255, green: 154/255, blue: 255/255, alpha: 0.8)
        } else {
            self.cornerRadius = bounds.height / 2
            self.borderWidth = 2
            self.borderColor = Color.clear
        }
    }


    override var isSelected: Bool {
        didSet {
            
            if isSelected {
                self.cornerRadius = bounds.height / 2
                self.borderWidth = 2
                self.borderColor = Color(red: 62/255, green: 154/255, blue: 255/255, alpha: 0.8)
            } else {
                self.cornerRadius = bounds.height / 2
                self.borderWidth = 2
                self.borderColor = Color.clear
            }
            
        }
    }

}
