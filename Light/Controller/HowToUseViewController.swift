//
//  HowToUseViewController.swift
//  Piano
//
//  Created by Kevin Kim on 18/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import CoreData

class HowToUseViewController: UIViewController {
    var context: NSManagedObjectContext!
    var checklistOff: String!
    var checklistOn: String!
    var list: String!
    
    private var prevChecklistOff: String!
    private var prevChecklistOn: String!
    private var prevList: String!
    
    var kbHeight: CGFloat = 300
    @IBOutlet weak var textView: DynamicTextView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotification()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unRegisterKeyboardNotification()
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        prevChecklistOff = LocalPreference.checkOffValue
        prevChecklistOn = LocalPreference.checkOnValue
        prevList = LocalPreference.unOrderedlistValue
        
        
        setNavigationBar(state: .normal)
        LocalPreference.checkOffValue = checklistOff
        LocalPreference.checkOnValue = checklistOn
        LocalPreference.unOrderedlistValue = list
        
        let attrText = "체크리스트를 적기 위해서는 @를 적고 띄어쓰기를 하면 선택했던 이모지로 변합니다.\n\n1. 체크리스트: @\n2. 리스트: -\n\n체크리스트 이모지를 터치해보세요.\n@ 체크리스트 1\n@ 체크리스트 2\n\n리스트를 적기 위해서는 -를 적고 띄어쓰기를 하면 선택했던 이모지로 변합니다.\n\n- 리스트1\n- 리스트2".createFormatAttrString()
        textView.attributedText = attrText
        setPreference()
    }
    
    @IBAction func complete(_ sender: Any) {
        activityIndicator.startAnimating()
        context.performAndWait {
            //1. Preference 코어데이터에 저장
            //2. 모든 Note를 돌아 이모지 체인지
            setAllNotes()
            context.saveIfNeeded()
            
            //3. 유저 디폴트 재 세팅
            UserDefaults.standard.set(true, forKey: UserDefaultsKey.isExistingUserKey)
            
            dismiss(animated: true, completion: nil)
        }
        
    }
    
    private func setAllNotes() {
        let noteRequest: NSFetchRequest<Note> = Note.fetchRequest()
        do {
            let notes = try context.fetch(noteRequest)
            notes.forEach {
                guard var text = $0.content else { return }
                
                var range = text.range(of: prevList)
                
                while range != nil, prevList != list {
                    text.replaceSubrange(range!, with: list)
                    range = text.range(of: prevList)
                }
                
                range = text.range(of: prevChecklistOn)
                
                while range != nil, prevChecklistOn != checklistOn {
                    text.replaceSubrange(range!, with: checklistOn)
                    range = text.range(of: prevChecklistOn)
                }
                
                range = text.range(of: prevChecklistOff)
                
                while range != nil, prevChecklistOff != checklistOff {
                    text.replaceSubrange(range!, with: checklistOff)
                    range = text.range(of: prevChecklistOff)
                }
                $0.content = text
                
            }
        } catch {
            print("모든 노트 돌면서 이모지 변경하다 에러: \(error.localizedDescription)")
        }
    }
    
    private func setPreference() {
        let preferenceRequest: NSFetchRequest<Preference> = Preference.fetchRequest()
        do {
            let preferenceCount = try context.count(for: preferenceRequest)
            if preferenceCount == 0 {
                let preference = Preference(context: context)
                preference.checklistOff = checklistOff
                preference.checklistOn = checklistOn
                preference.unorderedList = list
            } else {
                guard let preference = try context.fetch(preferenceRequest).first else { return }
                preference.checklistOff = checklistOff
                preference.checklistOn = checklistOn
                preference.unorderedList = list
            }
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
}

extension HowToUseViewController: TextViewDelegate {

    func textView(_ textView: TextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {

        let trimText = text.trimmingCharacters(in: .newlines)
        if trimText.count == 0 {
            textView.typingAttributes = LocalPreference.defaultTypingAttr
        }


        let bulletValue = BulletValue(text: textView.text, selectedRange: textView.selectedRange)

        //지우는 글자에 bullet이 포함되어 있다면
        if let bulletValue = bulletValue, textView.attributedText.attributedSubstring(from: range).string.contains(bulletValue.string) {
            let paraRange = (textView.text as NSString).paragraphRange(for: textView.selectedRange)
            textView.textStorage.setAttributes(LocalPreference.defaultAttr, range: paraRange)
            textView.typingAttributes = LocalPreference.defaultTypingAttr
        }


        var range = range
        if textView.shouldReset(bullet: bulletValue, range: range, replacementText: text) {
            textView.resetBullet(range: &range, bullet: bulletValue)
        }

        //        2. 개행일 경우 newLineOperation 체크하고 해당 로직 실행
        if textView.enterNewline(text) {

            if textView.shouldAddBullet(bullet: bulletValue, range: range) {
                textView.addBullet(range: &range, bullet: bulletValue)
                return false
            } else if textView.shouldDeleteBullet(bullet: bulletValue, range: range){
                textView.deleteBullet(range: &range, bullet: bulletValue)
                return false
            }

        }

        return true
    }

    func textViewDidChange(_ textView: TextView) {
        (textView as? DynamicTextView)?.hasEdit = true

        var selectedRange = textView.selectedRange
        var bulletKey = BulletKey(text: textView.text, selectedRange: selectedRange)
        if let uBullet = bulletKey {
            switch uBullet.type {
            case .orderedlist:
                textView.adjust(range: &selectedRange, bullet: &bulletKey)
                textView.transformTo(bullet: bulletKey)
                textView.adjustAfter(bullet: &bulletKey)
            default:
                textView.transformTo(bullet: bulletKey)
            }
        }
    }
    
}

extension HowToUseViewController {
    
    internal func registerKeyboardNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    internal func unRegisterKeyboardNotification(){
        NotificationCenter.default.removeObserver(self)
    }
    

    
    @objc func keyboardWillHide(_ notification: Notification) {
        setNavigationBar(state: .normal)
        textView.contentInset.bottom = 0
        textView.scrollIndicatorInsets.bottom = 0
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            var kbHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height,
            let _ = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
            else { return }
        
        
        kbHeight = kbHeight < 200 ? 300 : kbHeight
        self.kbHeight = kbHeight
    
        textView.contentInset.bottom = kbHeight
        textView.scrollIndicatorInsets.bottom = kbHeight
        
        setNavigationBar(state: .typing)
    }
    
    enum VCState {
        case normal
        case typing
    }
    
    internal func setNavigationBar(state: VCState){
        var btns: [BarButtonItem] = []
        
        switch state {
        case .normal:
            navigationItem.titleView = nil
            navigationItem.setLeftBarButtonItems(nil, animated: false)
        case .typing:
            btns.append(BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:))))
            navigationItem.titleView = nil
            navigationItem.setLeftBarButtonItems(nil, animated: false)
        }
        
        navigationItem.setRightBarButtonItems(btns, animated: false)
    }
    
    @IBAction func done(_ sender: Any) {
        Feedback.success()
        view.endEditing(true)
    }
}
