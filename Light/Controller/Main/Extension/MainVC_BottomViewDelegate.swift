//
//  MainVC_BottomViewDelegate.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreGraphics

extension MainViewController: BottomViewDelegate {
    func bottomView(_ bottomView: BottomView, keyboardWillHide height: CGFloat) {
        setEditButtonIfNeeded()
    }
    
    func bottomView(_ bottomView: BottomView, keyboardWillShow height: CGFloat) {
        setDoneButtonIfNeeded()
    }
    
    func bottomView(_ bottomView: BottomView, didFinishTyping text: String) {
        createNote(text: text)
    }
    
    
    func bottomView(_ bottomView: BottomView, textViewDidChange textView: TextView) {
        perform(#selector(requestQuery(_:)), with: textView.text, afterDelay: 0.3)
    }
    
}

extension MainViewController {
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
                self.noResultsView.isHidden = count != 0
                print("검색결과는 \(count) 개 입니다")
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

//    private func refreshFetchRequest(with text: String) {
//        guard text.count != 0 else {
//            noteFetchRequest.predicate = nil
//            refreshCollectionView()
//            return
//        }
//        noteFetchRequest.predicate = text.predicate(fieldName: "content")
//        refreshCollectionView()
//    }

    private func saveContext() {
        if mainContext.hasChanges {
            do {
                try mainContext.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    // for test
    func setupDummyNotes() {
        try? resultsController.performFetch()
        if resultsController.fetchedObjects?.count ?? 0 < 100 {
            for _ in 1...50000 {
                let note = Note(context: mainContext)
                note.content = "Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit. Aenean eu leo quam. Pellentesque ornare sem lacinia quam venenatis vestibulum. Aenean lacinia bibendum nulla sed consectetur. Nullam id dolor id nibh ultricies vehicula ut id elit. Donec sed odio dui. Nullam quis risus eget urna mollis ornare vel eu leo."
            }
            for _ in 1...5 {
                let note = Note(context: mainContext)
                note.content = "👻 apple Nullam id dolor id nibh ultricies vehicula ut id elit."
            }

            for _ in 1...5 {
                let note = Note(context: mainContext)
                note.content = "👻 bang Maecenas faucibus mollis interdum."
            }

            for _ in 1...5 {
                let note = Note(context: mainContext)
                note.content = "한글을 입력해서 더미 데이터를 만들어보자."
            }


            for _ in 1...5 {
                let note = Note(context: mainContext)
                note.content = "한글을 두드려서 더미 data를 만들자."
            }

            saveContext()
            try? resultsController.performFetch()
        }
    }
}

extension MainViewController {
    
    enum BarButtonType: Int {
        case edit = 0
        case done = 1
    }
    
    private func setDoneButtonIfNeeded() {
        if navigationItem.rightBarButtonItem == nil {
            setDoneBtn()
            return
        }
        
        if let rightBarItem = navigationItem.rightBarButtonItem,
            let type = BarButtonType(rawValue: rightBarItem.tag),
            type != .done {
            setDoneBtn()
            return
        }
        
    }
    
    private func setEditButtonIfNeeded() {
        if navigationItem.rightBarButtonItem == nil {
            setEditBtn()
        }
        
        if let rightBarItem = navigationItem.rightBarButtonItem,
            let type = BarButtonType(rawValue: rightBarItem.tag),
            type != .edit {
            setEditBtn()
        }
    }
    
    @IBAction func done(_ sender: Any) {
        bottomView.textView.resignFirstResponder()
    }
    
    @IBAction func edit(_ sender: Any) {
        
    }
    
    private func createNote(text: String) {
        let note = Note(context: mainContext)
        note.content = text
        note.createdDate = Date()
        note.modifiedDate = Date()
        note.connectData()
        saveContext()
    }

}

extension MainViewController {
    private func setDoneBtn(){
        let doneBtn = BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
        doneBtn.tag = 1
        navigationItem.setRightBarButton(doneBtn, animated: true)
    }
    
    private func setEditBtn(){
        let editBtn = BarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(edit(_:)))
        editBtn.tag = 0
        navigationItem.setRightBarButton(editBtn, animated: true)
    }
}
