//
//  MainVC_BottomViewDelegate.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreGraphics
import EventKit
import Contacts
import CoreData
import DifferenceKit

extension MainViewController: BottomViewDelegate {
    
    func bottomView(_ bottomView: BottomView, didFinishTyping attributedString: NSAttributedString) {
        syncController.createNote(with: attributedString, completionHandler: nil)
    }
    
    func bottomView(_ bottomView: BottomView, textViewDidChange textView: TextView) {
        if textView.text.tokenzied != inputTextCache {
            perform(#selector(requestQuery(_:)), with: textView.text, afterDelay: 0.4)
        }
        self.inputTextCache = textView.text.tokenzied
        
        perform(#selector(requestRecommand(_:)), with: textView, afterDelay: 0.2)
    }
    
}

extension MainViewController {
    
    @objc func requestRecommand(_ sender: Any?) {
        guard let textView = sender as? TextView else { return }
        let recommandOperation = RecommandOperation(text: textView.text, selectedRange: textView.selectedRange) { [weak self] (recommandable) in
            self?.bottomView.recommandData = recommandable
        }
        if recommandOperationQueue.operationCount > 0 {
            recommandOperationQueue.cancelAllOperations()
        }
        recommandOperationQueue.addOperation(recommandOperation)
    }
    
    
    /// persistent store에 검색 요청하는 메서드.
    /// 검색할 문자열의 길이가 30보다 작을 경우,
    /// 0.3초 이상 멈추는 경우에만 실제로 요청한다.
    ///
    /// - Parameter sender: 검색할 문자열
    @objc func requestQuery(_ sender: Any?) {
        guard let text = sender as? String,
            text.count < 30  else { return }

        syncController.search(with: text) { notes in
            OperationQueue.main.addOperation { [weak self] in
                guard let `self` = self else { return }
                let count = notes.count
                self.title = (count <= 0) ? "메모없음" : "\(count)개의 메모"
                self.refreshUI(with: notes.map { $0.wrapped })
            }
        }
    }
}
