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
        
        let firstParaStr = strArray.removeFirst()
        //데이터 소스에 넣고, 텍스트뷰에 넣자.
        
        pianoEditorView.dataSource[indexPath.section][indexPath.item] = pianoEditorView.dataSource[indexPath.section][indexPath.item] + firstParaStr
        
        cell.content = pianoEditorView.dataSource[indexPath.section][indexPath.item]
        
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
        pianoEditorView.hasEdit = true
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
}
