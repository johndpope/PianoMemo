//
//  EmojiTextField.swift
//  Piano
//
//  Created by Kevin Kim on 15/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class EmojiTextField: UITextField {

    override var textInputMode: UITextInputMode? {
        for mode in UITextInputMode.activeInputModes {
            if mode.primaryLanguage == "emoji" {
                return mode
            }
        }
        return nil
    }

}
