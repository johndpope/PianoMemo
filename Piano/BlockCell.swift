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
    var stringType: StringType = "" {
        didSet {
            //1. 텍스트 세팅
            textView.layoutManager.delegate = self
            textView.text = stringType.string
            
            
            //2. 필요 시 변환
            let bulletKey = BulletKey(text: stringType.string, selectedRange: NSMakeRange(0, 0))
            if let bulletable = bulletKey {
                convertForm(bulletable: bulletable)
            } else {
                setFormButton(bulletable: nil)
            }
            
            //3. fontType에 따라 반영
            textView.font = (stringType as? AttributedStringType)?.fontType.font ?? FormAttribute.defaultFont
            
            addCheckAttrIfNeeded()
            
        }
    }

    @IBOutlet weak var textView: BlockTextView!
    @IBOutlet weak var formButton: UIButton!
    
    
    var fontType: FontType?
    
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


extension BlockCell: NSLayoutManagerDelegate {
//    func layoutManager(_ layoutManager: NSLayoutManager, lineSpacingAfterGlyphAt glyphIndex: Int, withProposedLineFragmentRect rect: CGRect) -> CGFloat {
//        return FormAttribute.lineSpacing
//    }
//    
//    func layoutManager(_ layoutManager: NSLayoutManager, shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<CGRect>, lineFragmentUsedRect: UnsafeMutablePointer<CGRect>, baselineOffset: UnsafeMutablePointer<CGFloat>, in textContainer: NSTextContainer, forGlyphRange glyphRange: NSRange) -> Bool {
//        lineFragmentUsedRect.pointee.size.height -= FormAttribute.lineSpacing
//        return true
//    }
}
