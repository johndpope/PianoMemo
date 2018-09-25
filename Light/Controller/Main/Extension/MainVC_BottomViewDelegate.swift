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
        
        let fetchOperation = FetchNoteOperation(request: noteFetchRequest, controller: resultsController) { notes in
            OperationQueue.main.addOperation { [weak self] in
                guard let `self` = self else { return }
                let count = notes.count
                self.title = (count <= 0) ? "메모없음" : "\(count)개의 메모"
                self.collectionView.performBatchUpdates({
                    self.collectionView.reloadSections(IndexSet(integer: 0))
                }, completion: nil)
            }
        }
        fetchOperation.setRequest(with: text)
        if fetchOperationQueue.operationCount > 0 {
            fetchOperationQueue.cancelAllOperations()
        }
        fetchOperationQueue.addOperation(fetchOperation)
    }
    
    // for test
    func setupDummyNotes() {
        try? resultsController.performFetch()
        if resultsController.fetchedObjects?.count ?? 0 < 100 {
            for _ in 1...5 {
                let note = Note(context: backgroundContext)
                note.content = "Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit. Aenean eu leo quam. Pellentesque ornare sem lacinia quam venenatis vestibulum. Aenean lacinia bibendum nulla sed consectetur. Nullam id dolor id nibh ultricies vehicula ut id elit. Donec sed odio dui. Nullam quis risus eget urna mollis ornare vel eu leo."
            }
            for _ in 1...5 {
                let note = Note(context: backgroundContext)
                note.content = "👻 apple Nullam id dolor id nibh ultricies vehicula ut id elit."
            }

            for _ in 1...5 {
                let note = Note(context: backgroundContext)
                note.content = "👻 bang Maecenas faucibus mollis interdum."
            }

            for _ in 1...5 {
                let note = Note(context: backgroundContext)
                note.content = "한글을 입력해서 더미 데이터를 만들어보자."
            }


            for _ in 1...5 {
                let note = Note(context: backgroundContext)
                note.content = "한글을 두드려서 더미 data를 만들자."
            }

            saveBackgroundContext()
            try? resultsController.performFetch()
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

            self.performConnectVCIfNeeded(note: note)
        }
    }
    
    private func performConnectVCIfNeeded(note: Note) {
        let eventStore = EKEventStore()
        let remindersNotRegistered = note.remindersNotRegistered(store: eventStore)
        let eventsNotRegistered = note.eventsNotRegistered(store: eventStore)
        let contactsNotRegistered = note.contactsNotRegistered()
        //TODO: 다른 모델들도 적용하기
        guard remindersNotRegistered.count != 0
            || eventsNotRegistered.count != 0
            || contactsNotRegistered.count != 0 else { return }
        
        let noteRegisteredData = NotRegisteredData(note: note,
                                                   eventStore: eventStore,
                                                   remindersNotRegistered: remindersNotRegistered,
                                                   eventsNotRegistered: eventsNotRegistered,
                                                   contactsNotRegistered: contactsNotRegistered)
        
        
        DispatchQueue.main.async { [weak self] in
            self?.performSegue(withIdentifier: ConnectViewController.identifier, sender: noteRegisteredData)
        }
        
    }
    
    struct NotRegisteredData {
        let note: Note
        let eventStore: EKEventStore
        let remindersNotRegistered: [EKReminder]
        let eventsNotRegistered: [EKEvent]
        let contactsNotRegistered: [CNContact]
    }

}
