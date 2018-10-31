//
//  BlockCell.swift
//  Piano
//
//  Created by Kevin Kim on 22/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

//저장할 때에는 형광펜부터, 로드할 때에는 서식부터

class BlockCell: UITableViewCell {
    //dataSource
    var content: String = "" {
        didSet {
            formButton.setTitle(nil, for: .normal)
            
            set(content: content)
        }
    }
    
    private func set(content: String) {
        //우선순위 1. 헤더 2. 서식 3. 피아노 효과 순으로 입히기
        let mutableAttrString = NSMutableAttributedString(string: content, attributes: FormAttribute.defaultAttr)
        
        if let headerKey = HeaderKey(text: content, selectedRange: NSMakeRange(0, 0)) {
            //버튼에 들어갈 텍스트 확보(유저에게 노출되는 걸 희망하지 않으므로 텍스트 컬러 클리어 색깔로 만들기
            let attrStr = mutableAttrString.attributedSubstring(from: headerKey.rangeToRemove)
            formButton.setTitleColor(Color.lightGray, for: .normal)
            formButton.setTitle(attrStr.string, for: .normal)
            formButton.isHidden = false
            
            //텍스트뷰에 들어갈 텍스트 세팅
            mutableAttrString.replaceCharacters(in: headerKey.rangeToRemove, with: "")
            mutableAttrString.addAttributes([.font : headerKey.font], range: NSMakeRange(0, mutableAttrString.length))
            
        } else if let bulletKey = BulletKey(text: content, selectedRange: NSMakeRange(0, 0)) {
            //버튼에 들어갈 텍스트 확보(유저에게 노출되는 걸 희망하지 않으므로 텍스트 컬러 클리어 색깔로 만들기
            let attrStr = mutableAttrString.attributedSubstring(from: bulletKey.rangeToRemove)
            formButton.setTitleColor(Color.point, for: .normal)
            formButton.setTitle(attrStr.string.replacingOccurrences(of: bulletKey.string, with: bulletKey.value), for: .normal)
            formButton.isHidden = false
            //텍스트뷰에 들어갈 텍스트 세팅
            mutableAttrString.replaceCharacters(in: bulletKey.rangeToRemove, with: "")
            
            if bulletKey.type == .checklistOn {
                mutableAttrString.addAttributes(FormAttribute.strikeThroughAttr, range: NSMakeRange(0, mutableAttrString.length))
            }
            
        } else {
            formButton.isHidden = true
        }
        
        //TODO: 피아노 효과에 대한 것도 추가해야함
        while true {
            guard let highlightKey = HighlightKey(text: mutableAttrString.string, selectedRange: NSMakeRange(0, mutableAttrString.length)) else { break }
            
            mutableAttrString.addAttributes([.backgroundColor : Color.highlight], range: highlightKey.range)
            mutableAttrString.replaceCharacters(in: highlightKey.endDoubleColonRange, with: "")
            mutableAttrString.replaceCharacters(in: highlightKey.frontDoubleColonRange, with: "")
        }
        
        textView.attributedText = mutableAttrString
    }

    @IBOutlet weak var textView: BlockTextView!
    @IBOutlet weak var formButton: UIButton!
    weak var detailVC: Detail2ViewController?
    
    @IBAction func tapFormButton(_ sender: UIButton) {
        Feedback.success()
        toggleCheckIfNeeded(button: sender)
    }
    
    
    internal func saveToDataSource() {
        //데이터 소스에 저장하기
        guard let attrText = textView.attributedText,
            let indexPath = detailVC?.tableView.indexPath(for: self) else { return }
        let title = formButton.title(for: .normal)

        
        let mutableAttrString = NSMutableAttributedString(attributedString: attrText)
        
        //1. 피아노 효과부터 :: ::를 삽입해준다.
        var highlightRanges: [NSRange] = []
        mutableAttrString.enumerateAttribute(.backgroundColor, in: NSMakeRange(0, mutableAttrString.length), options: .reverse) { (value, range, _) in
            guard let color = value as? Color, color == Color.highlight else { return }
            highlightRanges.append(range)
        }
        //reverse로 했으므로 순차 탐색하면서 :: 넣어주면 된다.
        highlightRanges.forEach {
            mutableAttrString.replaceCharacters(in: NSMakeRange($0.upperBound, 0), with: "::")
            mutableAttrString.replaceCharacters(in: NSMakeRange($0.lowerBound, 0), with: "::")
        }
        
        //2. 버튼에 있는 걸 키로 만들어 삽입해준다.
        if let formStr = title,
            let _ = HeaderKey(text: formStr, selectedRange: NSMakeRange(0, 0)) {
            let attrString = NSAttributedString(string: formStr)
            mutableAttrString.insert(attrString, at: 0)
            
        } else if let formStr = title,
            let bulletValue = BulletValue(text: formStr, selectedRange: NSMakeRange(0, 0)) {
            let attrString = NSAttributedString(string: bulletValue.whitespaces.string + bulletValue.key + bulletValue.followStr)
            mutableAttrString.insert(attrString, at: 0)
        }
        
        detailVC?.dataSource[indexPath.section][indexPath.row] = mutableAttrString.string
    }
    

}

extension BlockCell {
    /**
     필요 시 취소선을 입혀주는 로직
     */
    internal func addCheckAttrIfNeeded() {
        guard textView.attributedText.length != 0 else { return }
        //체크 유무에 따라 서식 입히기
        let isCheck = (formButton.title(for: .normal) ?? "").contains(Preference.checklistOnValue)
        //맨 끝을 확인해야함
        let index = textView.attributedText.length - 1
        if isCheck {
            //첫번째 인덱스에 취소선이 입혀져있지 않는다면 입히기
            if let style = textView.attributedText.attribute(.strikethroughStyle, at: index, effectiveRange: nil) as? Int, style == 1 {
                //이미 입혀져 있음
            } else {
                let range = NSMakeRange(0, textView.attributedText.length)
                textView.textStorage.addAttributes(FormAttribute.strikeThroughAttr, range: range)
            }
            
        } else {
            //첫번째 인덱스에 취소선이 입혀져 있다면 지우기
            if let style = textView.attributedText.attribute(.strikethroughStyle, at: index, effectiveRange: nil) as? Int, style == 1 {
                let range = NSMakeRange(0, textView.attributedText.length)
                textView.textStorage.addAttributes(FormAttribute.defaultAttr, range: range)
            } else {
                //입혀져 있지 않음
            }
        }
    }
    
    /**
     필요 시 헤더를 입혀주는 로직
     */
    internal func addHeaderAttrIfNeeded() {
        guard textView.attributedText.length != 0 else { return }
        //체크 유무에 따라 서식 입히기
        guard let headerKey = HeaderKey(text: formButton.title(for: .normal) ?? "", selectedRange: NSMakeRange(0, 0)) else { return }
        //폰트 자체는 언어 지원에 따라 다를 수 있으므로, 폰트 사이즈로 비교한다.
        if let font = textView.attributedText.attribute(.font, at: 0, effectiveRange: nil) as? Font,
            font.pointSize != headerKey.font.pointSize {
            let range = NSMakeRange(0, textView.attributedText.length)
            textView.textStorage.addAttributes([.font : headerKey.font], range: range)
            
            UIView.performWithoutAnimation {
                detailVC?.tableView.performBatchUpdates(nil, completion: nil)
            }
        }
    }
    
    /**
     체크리스트 개행 시에 체크를 꺼주는 역할
     */
    internal func setCheckOffIfNeeded() {
        guard let text = formButton.title(for: .normal),
            text.contains(Preference.checklistOnValue),
            let bulletValue = BulletValue(text: text, selectedRange: NSMakeRange(0, 0)) else { return }
        
        let newText = (text as NSString).replacingCharacters(in: bulletValue.range, with: Preference.checklistOffValue)
        formButton.setTitle(newText, for: .normal)
    }
    
    /**
     서식 취소
     */
    internal func revertForm() {
        guard let title = formButton.title(for: .normal) else { return }
        //1. 버튼 리셋시키고, 히든시킨다.
        formButton.setTitle(nil, for: .normal)
        formButton.isHidden = true
        
        //현재는 아래의 두가지 경우밖에 없으며 고로 replaceCharacters를 모두 호출해준만큼 saveToDataSource가 호출될 것이다.
        if let headerKey = HeaderKey(text: title, selectedRange: NSMakeRange(0, 0)) {
            //2. 텍스트뷰 앞에 키를 넣어준다.
            let frontString = headerKey.whitespaces.string + headerKey.string
            let frontAttrString = NSAttributedString(string: frontString, attributes: Preference.defaultAttr)
            textView.replaceCharacters(in: NSMakeRange(0, 0), with: frontAttrString)
            
            textView.textStorage.addAttributes(FormAttribute.defaultAttr, range: NSMakeRange(0, textView.attributedText.length))
            
            
        } else if let bulletValue = BulletValue(text: title, selectedRange: NSMakeRange(0, 0)) {
            
            //2. 텍스트뷰 앞에 키를 넣어준다.
            let frontString = bulletValue.whitespaces.string + (bulletValue.type != .orderedlist ? bulletValue.key : bulletValue.key + ".")
            let frontAttrString = NSAttributedString(string: frontString, attributes: Preference.defaultAttr)
            textView.replaceCharacters(in: NSMakeRange(0, 0), with: frontAttrString)
            
            if bulletValue.type == .checklistOn {
                textView.textStorage.addAttributes(FormAttribute.defaultAttr, range: NSMakeRange(0, textView.attributedText.length))
            }
        }
        
        UIView.performWithoutAnimation {
            detailVC?.tableView.performBatchUpdates(nil, completion: nil)
        }
        
    }
    
    /**
     textViewDidChange에서 일어난다.
     */
    internal func convertForm(bulletable: Bulletable) {
        textView.textStorage.replaceCharacters(in: NSMakeRange(0, bulletable.baselineIndex), with: "")
//        textView.selectedRange.location -= bulletable.baselineIndex
        setFormButton(bulletable: bulletable)
        
        //서식이 체크리스트 on일 경우 글자 attr입혀주기
        if bulletable.type == .checklistOn {
            let range = NSMakeRange(0, textView.attributedText.length)
            textView.textStorage.addAttributes(FormAttribute.strikeThroughAttr, range: range)
        }
    }
    
    /**
     textViewDidChange에서 일어난다.
     */
    internal func convertHeader(headerKey: HeaderKey) {
        textView.textStorage.replaceCharacters(in: NSMakeRange(0, headerKey.baselineIndex), with: "")
//        textView.selectedRange.location -= headerKey.baselineIndex
        setFormButton(headerKey: headerKey)
    }
    
    
    internal func setFormButton(headerKey: HeaderKey) {
        let title = headerKey.whitespaces.string + headerKey.string + " "
        formButton.setTitle(title, for: .normal)
        formButton.setTitleColor(.lightGray, for: .normal)
        formButton.isHidden = false
    }
    
    
    /**
     orderedList일 경우 숫자를 맞춰주기 위해 쓰인다.
     */
    internal func setFormButton(bulletable: Bulletable?) {
        guard let bulletable = bulletable else {
            formButton.setTitle(nil, for: .normal)
            formButton.isHidden = true
            return
        }
        
        formButton.isHidden = false
        let title = bulletable.whitespaces.string + bulletable.value + (bulletable.type != .orderedlist ? " " : ". ")
        formButton.setTitle(title, for: .normal)
        formButton.setTitleColor(Color.point, for: .normal)
    }
    
    /**
     서식 제거
     */
    internal func removeForm() {
        //1. 버튼 리셋시키고, 히든시킨다.
        formButton.setTitle(nil, for: .normal)
        formButton.isHidden = true
        //saveToDataSource를 위한 로직
        textView.delegate?.textViewDidChange?(textView)
        
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
