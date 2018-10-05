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

extension MainViewController: BottomViewDelegate {
    
    func bottomView(_ bottomView: BottomView, didFinishTyping attributedString: NSAttributedString) {
        createNote(attributedString: attributedString)
    }
    
    func bottomView(_ bottomView: BottomView, textViewDidChange textView: TextView) {
        if textView.text.tokenzied != inputTextCache {
            perform(#selector(requestQuery(_:)), with: textView.text)
        }
        self.inputTextCache = textView.text.tokenzied
        perform(#selector(requestRecommand(_:)), with: textView)
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
        
        let fetchOperation = FetchNoteOperation(request: noteFetchRequest, controller: resultsController) { notes in
            OperationQueue.main.addOperation { [weak self] in
                guard let self = self else { return }
                self.title = self.inputTextCache.first ?? "All Notes".loc
                self.showEmptyStateViewIfNeeded(count: notes.count)

                
                self.collectionView.reloadData()
//                self.collectionView.performBatchUpdates({
//                    self.collectionView.reloadData()
//                }, completion: nil)
            }
        }
        fetchOperation.setRequest(with: text)
        if fetchOperationQueue.operationCount > 0 {
            fetchOperationQueue.cancelAllOperations()
        }
        fetchOperationQueue.addOperation(fetchOperation)
    }
    
    internal func showEmptyStateViewIfNeeded(count: Int){
        
        
//        emptyStateView.isHidden = count != 0
    }
    
    // for test
    func setupDummyNotes() {
        
        backgroundContext.performAndWait {
            
            for _ in 1...100 {
                let note = Note(context: backgroundContext)
                note.createdDate = Date()
                note.modifiedDate = Date()
                note.title = "Duis mollis, est non commodo luctus, nisi erat porttitor ligula"
                note.content = "Duis mollis, est non commodo luctus, nisi erat porttitor ligula"
            }
            
            
//            for _ in 0...5000 {
//                let note = Note(context: backgroundContext)
//                note.createdDate = Date()
//                note.modifiedDate = Date()
//                note.title = "Duis mollis, est non commodo luctus, nisi erat porttitor ligula"
//                note.content = "Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit. Aenean eu leo quam. Pellentesque ornare sem lacinia quam venenatis vestibulum. Aenean lacinia bibendum nulla sed consectetur. Nullam id dolor id nibh ultricies vehicula ut id elit. Donec sed odio dui. Nullam quis risus eget urna mollis ornare vel eu leo."
//            }
//
//            for _ in 1...500 {
//                let note = Note(context: backgroundContext)
//                note.createdDate = Date()
//                note.modifiedDate = Date()
//                note.title = "👻 apple Nullam id dolor id nibh ultricies vehicula ut id elit."
//                note.content = "👻 apple Nullam id dolor id nibh ultricies vehicula ut id elit."
//            }
//
//            for _ in 1...1000 {
//                let note = Note(context: backgroundContext)
//                note.createdDate = Date()
//                note.modifiedDate = Date()
//                note.title = "👻 bang Maecenas faucibus mollis interdum."
//                note.content = "👻 bang Maecenas faucibus mollis interdum."
//            }
//
//            for _ in 1...500 {
//                let note = Note(context: backgroundContext)
//                note.createdDate = Date()
//                note.modifiedDate = Date()
//                note.title = "한글을 입력해서 더미 데이터를 만들어보자."
//                note.content = "한글을 입력해서 더미 데이터를 만들어보자."
//            }
//
//
//            for _ in 1...500 {
//                let note = Note(context: backgroundContext)
//                note.createdDate = Date()
//                note.modifiedDate = Date()
//                note.title = "한글을 두드려서 더미 data를 만들자."
//                note.content = "한글을 두드려서 더미 data를 만들자."
//            }
            
            saveBackgroundContext()
        }
    }
    
    func saveBackgroundContext() {
        guard backgroundContext.hasChanges else { return }
        do {
            try backgroundContext.save()
        } catch {
            print("저장하는 데 에러!")
        }
    }
}

extension MainViewController {
    
    private func createNote(attributedString: NSAttributedString) {
        backgroundContext.perform { [weak self] in
            guard let `self` = self else { return }
            let note = Note(context: self.backgroundContext)
            note.save(from: attributedString)
        }
    }

}
