//
//  BlockTVCell_textViewDelegate.swift
//  Piano
//
//  Created by Kevin Kim on 21/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension TextBlockTableViewCell: TextViewDelegate {
    func textViewShouldBeginEditing(_ textView: TextView) -> Bool {
        guard let vc = blockTableVC else { return false }
        return vc.blockTableState == .normal(.typing)
            || vc.blockTableState == .normal(.read)
    }

    func textViewDidChange(_ textView: TextView) {
        guard let vc = blockTableVC,
            let indexPath = vc.tableView.indexPath(for: self) else { return }
//        vc.resetTimer()
        let headerStrCount = headerButton.title(for: .normal)?.count ?? 0
        let formStrCount = formButton.title(for: .normal)?.count ?? 0

        if headerStrCount == 0 && formStrCount == 0 {
            if let headerKey = HeaderKey(
                text: textView.text,
                selectedRange: textView.selectedRange) {
                convert(headerKey: headerKey)
            } else if var bulletShortcut = PianoBullet(
                type: .shortcut,
                text: textView.text,
                selectedRange: textView.selectedRange) {

                if bulletShortcut.isOrdered {
                    if indexPath.row != 0 {
                        let prevIndexPath = IndexPath(
                            row: indexPath.row - 1,
                            section: indexPath.section)
                        bulletShortcut = adjust(prevIndexPath: prevIndexPath, for: bulletShortcut)
                    }
                    convert(bulletShortcut: bulletShortcut)
                    adjustAfter(currentIndexPath: indexPath, pianoBullet: bulletShortcut)
                } else {
                    convert(bulletShortcut: bulletShortcut)
                }
            } else if let pianoAssetKey = PianoAssetKey(
                type: .shortcut,
                text: textView.text,
                selectedRange: textView.selectedRange) {
                //현재 indexPath에 셀렉션 데이터 소스를 넣어주고 테이블 뷰 업데이트 해줘야 할듯.
                let assetGridStr = "![](asset://)"
                vc.dataSource[indexPath.section].insert(assetGridStr, at: indexPath.row)
                //테이블 뷰에 삽입된 데이터 보여주기
                View.performWithoutAnimation {
                    vc.tableView.insertRows(
                        at: [indexPath],
                        with: .none)
                }
                textView.text = ""
                layoutCellIfNeeded(textView)

                //커서가 키보드 위로 항상 유지
                var nextIndexPath = indexPath
                nextIndexPath.row += 1
                vc.tableView.scrollToRow(at: nextIndexPath, at: .none, animated: true)
                return
            }
        }

        addCheckAttrIfNeeded()
        addHeaderAttrIfNeeded()
        layoutCellIfNeeded(textView)
    }

    func textViewDidBeginEditing(_ textView: TextView) {
        //TODO: tap제스쳐에 따라 텍스트뷰 editable을 꺼주고, begin이 된 순간, 탭 재스쳐 enable을 끈다.
        guard let vc = blockTableVC else { return }
        vc.blockTableState = .normal(.typing)
    }

    func textViewDidEndEditing(_ textView: TextView) {
        //TODO: 텍스트 타이핑이 끝날을 때, 다시 탭 재스쳐 이네이블을 켜주고, 텍스트뷰 editable을 꺼준다.
        guard let vc = blockTableVC else { return }
        vc.blockTableState = .normal(.read)
        saveToDataSource()
    }

    func textView(_ textView: TextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let vc = blockTableVC,
            let indexPath = vc.tableView.indexPath(for: self),
            textView.text.count < 1000,
            text.count < 1000 else { return false }

        let situation = typingSituation(
            cell: self,
            indexPath: indexPath,
            selectedRange: textView.selectedRange,
            replacementText: text)

        switch situation {
        case .revertForm:
            revertForm()
        case .removeForm:
            removeForm()
        case .split:
            split()
        case .combine:
            combine()
        case .stayCurrent:
            return true
        }

        View.performWithoutAnimation {
            vc.tableView.performBatchUpdates(nil, completion: nil)
        }
        return false
    }
}
