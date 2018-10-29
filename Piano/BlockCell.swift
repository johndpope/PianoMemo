//
//  BlockCell.swift
//  Piano
//
//  Created by Kevin Kim on 22/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class BlockCell: UITableViewCell {
    //dataSource
    var content: String = "" {
        didSet {
            //1. 텍스트 세팅
            textView.text = content
            
            //2. 필요 시 변환
            let bulletKey = BulletKey(text: content, selectedRange: NSMakeRange(0, 0))
            if let bulletable = bulletKey {
                convertForm(bulletable: bulletable)
            } else {
                setFormButton(bulletable: nil)
            }
            
            //3. fontType에 따라 반영
            //TODO: 작업 진행하기
            
            addCheckAttrIfNeeded()
        }
    }

    //타이핑하다가 저장안하고 스크롤 하다가 앱을 종료했을 때, 테이블뷰가 해당 인덱스 패스의 
    internal var indexPath: IndexPath = IndexPath(row: 0, section: 0)
    @IBOutlet weak var textView: BlockTextView!
    @IBOutlet weak var formButton: UIButton!
    weak var detailVC: Detail2ViewController?
    
    @IBAction func tapFormButton(_ sender: UIButton) {
        Feedback.success()
        toggleCheckIfNeeded(button: sender)
    }
    
    internal func saveToDataSource() {
        //데이터 소스에 저장하기
        //fontType, 서식을 키로 바꿔주고 텍스트와 결합해서 저장해야함
        guard var text = textView.text else { return }
        
        if let str = formButton.title(for: .normal),
            let bulletValue = BulletValue(text: str, selectedRange: NSMakeRange(0, 0)) {
            text = bulletValue.whitespaces.string + bulletValue.key + bulletValue.followStr + text
        }
        
        detailVC?.dataSource[indexPath.section][indexPath.row] = text
    }
    

}

extension BlockCell {
    internal func addCheckAttrIfNeeded() {
        guard textView.attributedText.length != 0 else { return }
        //체크 유무에 따라 서식 입히기
        let isCheck = (formButton.title(for: .normal) ?? "").contains(Preference.checklistOnValue)
        if isCheck {
            //첫번째 인덱스에 취소선이 입혀져있지 않는다면 입히기
            if let style = textView.attributedText.attribute(.strikethroughStyle, at: 0, effectiveRange: nil) as? Int, style == 1 {
                //이미 입혀져 있음
            } else {
                let range = NSMakeRange(0, textView.attributedText.length)
                textView.textStorage.addAttributes(FormAttribute.strikeThroughAttr, range: range)
            }
            
        } else {
            //첫번째 인덱스에 취소선이 입혀져 있다면 지우기
            if let style = textView.attributedText.attribute(.strikethroughStyle, at: 0, effectiveRange: nil) as? Int, style == 1 {
                let range = NSMakeRange(0, textView.attributedText.length)
                textView.textStorage.addAttributes(FormAttribute.defaultAttr, range: range)
            } else {
                //입혀져 있지 않음
            }
        }
    }
    
    internal func setCheckOffIfNeeded() {
        guard let text = formButton.title(for: .normal),
            text.contains(Preference.checklistOnValue),
            let bulletValue = BulletValue(text: text, selectedRange: NSMakeRange(0, 0)) else { return }
        
        let newText = (text as NSString).replacingCharacters(in: bulletValue.range, with: Preference.checklistOffValue)
        formButton.setTitle(newText, for: .normal)
    }
    
    internal func revertForm() {
        guard let title = formButton.title(for: .normal),
            let bulletValue = BulletValue(text: title, selectedRange: NSMakeRange(0, 0)) else { return }
        
        //1. 버튼 리셋시키고, 히든시킨다.
        formButton.setTitle(nil, for: .normal)
        formButton.isHidden = true
        
        //2. 텍스트뷰 앞에 키를 넣어준다.
        let frontString = bulletValue.whitespaces.string + (bulletValue.type != .orderedlist ? bulletValue.key : bulletValue.key + ".")
        let frontAttrString = NSAttributedString(string: frontString, attributes: Preference.defaultAttr)
        textView.replaceCharacters(in: NSMakeRange(0, 0), with: frontAttrString)
        
    }
    
    internal func removeForm() {
        //1. 버튼 리셋시키고, 히든시킨다.
        formButton.setTitle(nil, for: .normal)
        formButton.isHidden = true
        
    }
    
    internal func convertForm(bulletable: Bulletable) {
        textView.textStorage.replaceCharacters(in: NSMakeRange(0, bulletable.baselineIndex), with: "")
        textView.selectedRange = NSMakeRange(0, 0)
        setFormButton(bulletable: bulletable)
        
        //서식이 체크리스트 on일 경우 글자 attr입혀주기
        if bulletable.type == .checklistOn {
            let range = NSMakeRange(0, textView.attributedText.length)
            textView.textStorage.addAttributes(FormAttribute.strikeThroughAttr, range: range)
        }
    }
    
    //서식을 대입해주는 로직(셀 데이터의 didSet에서 쓰이고, 외부에서도 서식값만을 바꾸고 싶을 때 쓰인다.
    internal func setFormButton(bulletable: Bulletable?) {
        guard let bulletable = bulletable else {
            formButton.setTitle(nil, for: .normal)
            formButton.isHidden = true
            return
        }
        
        formButton.isHidden = false
        let title = bulletable.whitespaces.string + bulletable.value + (bulletable.type != .orderedlist ? " " : ". ")
        formButton.setTitle(title, for: .normal)
    }

}

extension BlockCell {
    private func toggleCheckIfNeeded(button: UIButton) {
        
        guard let form = button.title(for: .normal),
            let bulletValue = BulletValue(text: form, selectedRange: NSMakeRange(0, 0)),
            (bulletValue.type == .checklistOn || bulletValue.type == .checklistOff) else { return }
        let isCheck = bulletValue.type == .checklistOn
        
        let changeStr = (form as NSString).replacingCharacters(in: bulletValue.range, with: isCheck ? Preference.checklistOffValue : Preference.checklistOnValue)
        
        //버튼 타이틀 바꾸고
        button.setTitle(changeStr, for: .normal)
        //텍스트뷰 어트리뷰트 입혀주고
        let attr = isCheck ? FormAttribute.defaultAttr : FormAttribute.strikeThroughAttr
        let range = NSMakeRange(0, textView.attributedText.length)
        textView.textStorage.addAttributes(attr, range: range)
        
        //데이터 소스 갱신시키기
        saveToDataSource()
    }
}
