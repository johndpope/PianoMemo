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
    
    func bottomView(_ bottomView: BottomView, didFinishTyping text: String) {
        createNote(text: text)
    }
    
    
    func bottomView(_ bottomView: BottomView, textViewDidChange textView: TextView) {
        typingCounter += 1
        perform(#selector(requestQuery(_:)), with: textView.text, afterDelay: searchRequestDelay)
    }
    
}

extension MainViewController {
    
    
    /// persistent store에 검색 요청하는 메서드.
    /// 검색할 문자열의 길이가 30보다 작을 경우,
    /// 0.3초 이상 멈추는 경우에만 실제로 요청한다.
    ///
    /// - Parameter sender: 검색할 문자열
    @objc func requestQuery(_ sender: Any?) {
        typingCounter -= 1
        guard let text = sender as? String,
            typingCounter == 0,
            text.count < 30  else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.refreshFetchRequest(with: text)
        }
    }

    private func refreshFetchRequest(with text: String) {
        guard text.count != 0 else {
            noteFetchRequest.predicate = nil
            refreshCollectionView()
            return
        }
        noteFetchRequest.predicate = text.predicate(fieldName: "content")
        refreshCollectionView()
    }

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
        try? resultsController?.performFetch()
        if resultsController?.fetchedObjects?.count ?? 0 < 100 {
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
            try? resultsController?.performFetch()
        }
    }
}

extension MainViewController {
    
    private func createNote(text: String) {
        let note = Note(context: mainContext)
        note.content = text
        note.createdDate = Date()
        note.modifiedDate = Date()
        note.connectData()
        saveContext()
    }

}
