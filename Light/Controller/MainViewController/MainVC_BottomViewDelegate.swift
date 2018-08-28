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
        let note = Note(context: mainContext)
        note.content = text
        note.createdDate = Date()
        note.modifiedDate = Date()
        saveContext()
        
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
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.refreshFetchRequest(with: text)
        }
    }
    
    private func refreshFetchRequest(with text: String) {
        guard text.count != 0 else {
            noteFetchRequest.predicate = nil
            DispatchQueue.main.async { [weak self] in
                self?.refreshCollectionView()
            }
            return
        }
        
        if let language = NSLinguisticTagger.dominantLanguage(for: text),
            NSLinguisticTagger.availableTagSchemes(forLanguage: language).contains(.lexicalClass) {
            
            linguisticRequest(with: text)
            
        } else {
            fullTextRequest(with: text)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.refreshCollectionView()
        }
    }
    
    private func linguisticRequest(with text: String) {
        let tagger = NSLinguisticTagger(tagSchemes: [.lexicalClass], options: 0)
        tagger.string = text
        
        let range = NSRange(location: 0, length: text.utf16.count)
        let options: NSLinguisticTagger.Options = [.omitWhitespace]
        let tags: [NSLinguisticTag] = [.noun, .verb, .otherWord, .number]
        var words = Array<String>()
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange, stop in
            
            if let tag = tag, tags.contains(tag) {
                let word = (text as NSString).substring(with: tokenRange)
                words.append(word)
            }
        }
        let predicates = Set(words)
            .map { $0.lowercased() }
            .map { NSPredicate(format: "content contains[cd] %@", $0) }
        
        noteFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    private func fullTextRequest(with text: String) {
        let trimmed = text.lowercased()
            .trimmingCharacters(in: .illegalCharacters)
            .trimmingCharacters(in: .punctuationCharacters)
        
        let predicate = NSPredicate(format: "content contains[cd] %@", trimmed)
        noteFetchRequest.predicate = predicate
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
        
    }
    
    @IBAction func edit(_ sender: Any) {
        
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
