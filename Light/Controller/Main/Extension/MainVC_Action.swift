//
//  MainVC_Action.swift
//  Piano
//
//  Created by Kevin Kim on 17/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

extension MainViewController {
    
    @IBAction func erase(_ sender: Button) {
        bottomView.textView.text = ""
        bottomView.textView.insertText("")
        bottomView.textView.typingAttributes = Preference.defaultAttr
    }
    
 
}
