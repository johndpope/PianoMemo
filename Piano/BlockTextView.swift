//
//  BlockTextView.swift
//  Piano
//
//  Created by Kevin Kim on 03/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class BlockTextView: UITextView {
    weak var blockTableVC: BlockTableViewController?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        textContainerInset = UIEdgeInsets(top: 5, left: 8, bottom: 0, right: 8)
        textContainer.lineFragmentPadding = 0
    }

    override func paste(_ sender: Any?) {
        guard let blockTableVC = blockTableVC,
            let str = UIPasteboard.general.string,
            let cell = superview?.superview?.superview as? BlockTableViewCell,
            let indexPath = blockTableVC.tableView.indexPath(for: cell) else { return }

        var strArray = str.components(separatedBy: .newlines)

        //1000문단 이하일 경우에만 키로 바꿔준다.
        if strArray.count < Preference.paraLimit {
            strArray = strArray.map { $0.convertEmojiToKey() }
        }

        let firstParaStr = strArray.removeFirst()
        //데이터 소스에 넣고, 텍스트뷰에 넣자.

        insertText(firstParaStr)
        delegate?.textViewDidChange?(self)

        let cache = selectedRange

        cell.data = blockTableVC.dataSource[indexPath.section][indexPath.item]

        selectedRange = cache

        guard strArray.count != 0 else {
            return
        }

        resignFirstResponder()

        let nextIndex = indexPath.row + 1
        blockTableVC.dataSource[indexPath.section].insert(contentsOf: strArray, at: nextIndex)
        blockTableVC.tableView.reloadData()

        var desIndexPath = indexPath
        desIndexPath.row += strArray.count
        blockTableVC.tableView.scrollToRow(at: desIndexPath, at: .bottom, animated: true)
        blockTableVC.hasEdit = true
    }
}
