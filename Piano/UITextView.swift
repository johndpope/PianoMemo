//
//  UITextView.swift
//  Piano
//
//  Created by hoemoon on 28/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

extension UITextView {
    func invalidateCaretPosition() {
        let newPosition = self.beginningOfDocument
        self.selectedTextRange = self.textRange(from: newPosition, to: newPosition)
    }
}
