//
//  BlockTextView.swift
//  Piano
//
//  Created by Kevin Kim on 03/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class BlockTextView: UITextView {
    weak var pianoEditorView: PianoEditorView?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        textContainerInset = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
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
        guard let str = UIPasteboard.general.string,
            let cell = superview?.superview?.superview as? BlockCell,
            let indexPath = pianoEditorView?.tableView.indexPath(for: cell) else { return }
        
        
        var strArray = str.components(separatedBy: .newlines)
        
        //1000문단 이하일 경우에만 키로 바꿔준다.
        if strArray.count < Preference.paraLimit {
            strArray = strArray.map { $0.convertEmojiToKey() }
        }
        
        
        var firstParaStr = strArray.removeFirst()
        //데이터 소스에 넣고, 텍스트뷰에 넣자.
        
        while true {
            guard let highlightKey = HighlightKey(text: firstParaStr, selectedRange: NSMakeRange(0, firstParaStr.utf16.count)) else { break }
            
            firstParaStr = (firstParaStr as NSString).replacingCharacters(in: highlightKey.endDoubleColonRange, with: "")
            firstParaStr = (firstParaStr as NSString).replacingCharacters(in: highlightKey.frontDoubleColonRange, with: "")
        }
        
        replaceCharacters(in: selectedRange, with: NSAttributedString(string: firstParaStr, attributes: FormAttribute.defaultAttr))
        
        guard strArray.count != 0 else {
            return
        }

        resignFirstResponder()
        
        let nextIndex = indexPath.row + 1
        pianoEditorView?.dataSource[indexPath.section].insert(contentsOf: strArray, at: nextIndex)
        pianoEditorView?.tableView.reloadData()
        
        var desIndexPath = indexPath
        desIndexPath.row += strArray.count
        pianoEditorView?.tableView.scrollToRow(at: desIndexPath, at: .bottom, animated: true)
        pianoEditorView?.hasEdit = true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
}
