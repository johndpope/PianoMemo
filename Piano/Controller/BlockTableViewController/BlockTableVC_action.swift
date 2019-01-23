//
//  BlockTableVC_action.swift
//  Piano
//
//  Created by Kevin Kim on 17/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension BlockTableViewController {
    
    @IBAction func tapBackground(_ sender: TapGestureRecognizer) {
        //TODO: 이부분 제대로 동작하는 지 체크(제대로 동작한다면, enum에 단순히 Equatable만 적어주면 된다.
        guard blockTableState == .normal(.typing)
            || blockTableState == .normal(.read) else { return }
        
        let point = sender.location(in: self.tableView)
        if let indexPath = tableView.indexPathForRow(at: point),
            let cell = tableView.cellForRow(at: indexPath) as? BlockTableViewCell {
            if point.x < self.tableView.center.x {
                //앞쪽에 배치
                cell.textView.selectedRange = NSRange(location: 0, length: 0)
                if !cell.textView.isFirstResponder {
                    cell.textView.becomeFirstResponder()
                }
            } else {
                //뒤쪽에 배치
                cell.textView.selectedRange = NSRange(location: cell.textView.attributedText.length, length: 0)
                if !cell.textView.isFirstResponder {
                    cell.textView.becomeFirstResponder()
                }
            }
        } else {
            //마지막 셀이 존재한다면(없다면 생성하기), 마지막 셀의 마지막 부분에 커서를 띄운다.
            if let count = dataSource.first?.count,
                count != 0,
                dataSource.count != 0 {
                let row = count - 1
                let indexPath = IndexPath(row: row, section: dataSource.count - 1)
                guard let cell = tableView.cellForRow(at: indexPath) as? BlockTableViewCell else { return }
                cell.textView.selectedRange = NSRange(location: cell.textView.attributedText.length, length: 0)
                if !cell.textView.isFirstResponder {
                    cell.textView.becomeFirstResponder()
                }
            }
        }
    }
    
    @IBAction func tapTrash(_ sender: Any) {
        Feedback.success()
        navigationController?.popViewController(animated: true)
        Analytics.deleteNoteAt = "editorToolBar"
        noteHandler.remove(notes: [note])
    }

    @IBAction func tapTimer(_ sender: Any) {

    }

    @IBAction func tapPiano(_ sender: Any) {

    }

    @IBAction func tapShare(_ sender: Any) {

    }

    @IBAction func tapCompose(_ sender: Any) {

    }

    @IBAction func tapDonePiano(_ sender: Any) {

    }

    @IBAction func tapSelectScreenArea(_ sender: Any) {

    }

    @IBAction func tapReminder(_ sender: Any) {

    }

    @IBAction func tapCopy(_ sender: Any) {

    }

    @IBAction func tapCut(_ sender: Any) {

    }

    @IBAction func tapDelete(_ sender: Any) {

    }

    @IBAction func tapPermanentDelete(_ sender: Any) {

    }

    @IBAction func tapRestore(_ sender: Any) {

    }

}
