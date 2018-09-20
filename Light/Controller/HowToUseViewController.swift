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
    var checklistOff: String!
    var checklistOn: String!
    var firstlist: String!
    var secondlist: String!
    
    var kbHeight: CGFloat = 300
    @IBOutlet weak var textView: DynamicTextView!
    
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
        
        Preference.checklistOffValue = checklistOff
        Preference.checklistOnValue = checklistOn
        Preference.firstlistValue = firstlist
        Preference.secondlistValue = secondlist
        
        setNavigationBar(state: .normal)
        
        let attrText = ":를 적고 띄어쓰기하면 체크리스트로 변합니다.\n: 애플스토어에서 아이폰 구입하기\n; 에어팟 구매하기\n\n-를 적고 띄어쓰기하면 첫번째 이모지로 변합니다.\n- 스티브잡스 전기 읽기\n- 조니아이브 책 읽기\n\n\n*를 적고 띄어쓰기하면 두번째 이모지로 변합니다.\n* 미친듯이 심플 읽기\n* 인사이드 애플 읽기".createFormatAttrString()
        textView.attributedText = attrText
        
    }
    
    @IBAction func complete(_ sender: Any) {
        
        
        UserDefaults.standard.set(true, forKey: UserDefaultsKey.isExistingUserKey)
        
        dismiss(animated: true, completion: nil)
        
        UserDefaults.standard.set(true, forKey: UserDefaultsKey.isExistingUserKey)
        dismiss(animated: true, completion: nil)
    }
    
}

extension HowToUseViewController: TextViewDelegate {

    func textView(_ textView: TextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {

        let trimText = text.trimmingCharacters(in: .newlines)
        if trimText.count == 0 {
            textView.typingAttributes = Preference.defaultTypingAttr
        }


        let bulletValue = BulletValue(text: textView.text, selectedRange: textView.selectedRange)

        //지우는 글자에 bullet이 포함되어 있다면
        if let bulletValue = bulletValue, textView.attributedText.attributedSubstring(from: range).string.contains(bulletValue.string) {
            let paraRange = (textView.text as NSString).paragraphRange(for: textView.selectedRange)
            textView.textStorage.addAttributes(Preference.defaultAttr, range: paraRange)
            textView.typingAttributes = Preference.defaultTypingAttr
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
