//
//  BlockTextView.swift
//  Piano
//
//  Created by Kevin Kim on 03/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class BlockTextView: UITextView {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        textContainerInset = UIEdgeInsets.zero
        textContainer.lineFragmentPadding = 0
    }
    
    //TODO: 여기서 해당 지점의 attrText의 attr에 링크가 있는 지 판단하는게 옳은것인가?
    /*
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let point = touches.first?.location(in: self) else { return }
        let index = layoutManager.glyphIndex(for: point, in: textContainer)
        
        if index < 0 {
            print("에러!!! textView에서 touchesEnd에 음수이면 안되는 index가 입력되었다!")
        }
        
        if attributedText.length != 0 && attributedText.attribute(.link, at: index, effectiveRange: nil) != nil {
            return
        } else {
            selectedRange.location = index + 1
            isEditable = true
            becomeFirstResponder()
        }
    }
    */
    override func paste(_ sender: Any?) {
        guard let string = UIPasteboard.general.string else { return }
        let attrString = string.createFormatAttrString(fromPasteboard: false)
        textStorage.replaceCharacters(in: selectedRange, with: attrString)
        delegate?.textViewDidChange?(self)
        
        if attrString.length < Preference.limitPasteStrCount {
            selectedRange.location += attrString.length
            selectedRange.length = 0
        }
    }
    
}
