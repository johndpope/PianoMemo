//
//  BlockTextViewAccessoryView.swift
//  Piano
//
//  Created by Kevin Kim on 01/02/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class BlockTextViewAccessoryView: TransparentToolbar {

    weak var textView: BlockTextView?
    
//    internal func setSuggestion(
    
    @IBAction func tapUndo(_ sender: UIBarButtonItem) {
        
    }
    
    @IBAction func tapRedo(_ sender: UIBarButtonItem) {
        
    }
    
    @IBAction func tapDone(_ sender: UIBarButtonItem) {
        textView?.resignFirstResponder()
    }

}
