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
        textContainerInset = UIEdgeInsets(top: 5, left: 8, bottom: 0, right: 8)
        textContainer.lineFragmentPadding = 0
    }

    override func paste(_ sender: Any?) {
        guard let pianoEditorView = pianoEditorView,
            let str = UIPasteboard.general.string,
            let cell = superview?.superview?.superview as? BlockCell,
            let indexPath = pianoEditorView.tableView.indexPath(for: cell) else { return }

        var strArray = str.components(separatedBy: .newlines)

        //1000문단 이하일 경우에만 키로 바꿔준다.
        if strArray.count < Preference.paraLimit {
            strArray = strArray.map { $0.convertEmojiToKey() }
        }

        var firstParaStr = strArray.removeFirst()
        //데이터 소스에 넣고, 텍스트뷰에 넣자.
        
        if let pianoKey = PianoBullet(type: .key,
                                      text: firstParaStr,
                                      selectedRange: NSRange(location: 0, length: 0)),
            (cell.formButton.title(for: .normal) != nil || cell.headerButton.title(for: .normal) != nil) {
            firstParaStr = (firstParaStr as NSString).substring(from: pianoKey.baselineIndex)
        }

        //헤더가 있거나, 혹은 체크리스트가 있을 때, firstParaStr에 키 값이 있다면 키를 없애주자.
        //체크리스트 버튼에 뭔가 있다면,
        
        
        insertText(firstParaStr)
        delegate?.textViewDidChange?(self)

        let cache = selectedRange

        cell.content = pianoEditorView.dataSource[indexPath.section][indexPath.item]

        selectedRange = cache

        guard strArray.count != 0 else {
            return
        }

        resignFirstResponder()

        let nextIndex = indexPath.row + 1
        pianoEditorView.dataSource[indexPath.section].insert(contentsOf: strArray, at: nextIndex)
        pianoEditorView.tableView.reloadData()

        var desIndexPath = indexPath
        desIndexPath.row += strArray.count
        pianoEditorView.tableView.scrollToRow(at: desIndexPath, at: .bottom, animated: true)
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
}
