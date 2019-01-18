//
//  BlockTableViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 18/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class BlockTableViewCell: UITableViewCell {
    
    @IBOutlet weak var textView: BlockTextView!
    @IBOutlet weak var formButton: UIButton!
    @IBOutlet weak var headerButton: UIButton!
    weak var blockTableVC: BlockTableViewController?
    
    var data: String {
        get {
            
            //TODO: 이부분 계산해서 적용시켜야함
            return ""
        } set {
            setup(string: newValue)
        }
    }
    
    internal func setupForPianoIfNeeded() {
        guard let vc = blockTableVC else { return }
        
        if vc.blockTableState == .normal(.piano) {
            textView.isEditable = false
            textView.isSelectable = false
            
            guard let pianoControl = textView.createSubviewIfNeeded(PianoControl.self),
                let pianoView = vc.navigationController?.view.subView(PianoView.self) else { return }
            
            pianoControl.attach(on: textView)
            pianoControl.textView = textView
            pianoControl.pianoView = pianoView
            
        } else {
            textView.isEditable = true
            textView.isSelectable = true
            textView.cleanPiano()
            
        }
        
    }
    
    private func setup(string: String) {
        //히든 유무와 세팅 유무는 모든 뷰들에게 할당이 되어야 한다(prepareForReuse에서 안하려면)
        //단 textView beginEditing일 때, 텍스트 카운트가 0이라면 typingAttribute는 세팅해줘야한다.
        let mutableAttrString = NSMutableAttributedString(
            string: string,
            attributes: FormAttribute.defaultAttr)
        
        if let headerKey = HeaderKey(
            text: string,
            selectedRange: NSRange(location: 0, length: 0)) {
            //setting
            let attrStr = mutableAttrString.attributedSubstring(from: headerKey.rangeToRemove)
            headerButton.setTitle(attrStr.string, for: .normal)
            //hidden
            headerButton.isHidden = false
            
            //header 관련 텍스트 없애기
            mutableAttrString.replaceCharacters(in: headerKey.rangeToRemove, with: "")
            mutableAttrString.addAttributes([.font: headerKey.font], range: NSRange(location: 0, length: mutableAttrString.length))
            
        } else if let bulletKey = PianoBullet(
            type: .key,
            text: string,
            selectedRange: NSRange(location: 0, length: 0)) {
            
            let attrStr = mutableAttrString.attributedSubstring(from: bulletKey.rangeToRemove)
            formButton.setTitle(attrStr.string.replacingOccurrences(of: bulletKey.string, with: bulletKey.value), for: .normal)
            formButton.isHidden = false
            
            //bullet관련 텍스트 없애기
            mutableAttrString.replaceCharacters(in: bulletKey.rangeToRemove, with: "")
            
            //체크온이면 strikeThrough 입혀주기
            if bulletKey.isOn {
                mutableAttrString.addAttributes(
                    FormAttribute.strikeThroughAttr,
                    range: NSRange(location: 0, length: mutableAttrString.length))
            }
        } else {
            formButton.isHidden = true
            formButton.setTitle(nil, for: .normal)
            headerButton.isHidden = true
            headerButton.setTitle(nil, for: .normal)
        }
        
        while true {
            guard let highlightKey = HighlightKey(
                text: mutableAttrString.string,
                selectedRange: NSRange(location: 0, length: mutableAttrString.length)) else { break }
            
            mutableAttrString.addAttributes(
                [.backgroundColor : Color.highlight],
                range: highlightKey.range)
            
            mutableAttrString.replaceCharacters(in: highlightKey.endDoubleColonRange, with: "")
            mutableAttrString.replaceCharacters(in: highlightKey.frontDoubleColonRange, with: "")
        }
        
        //텍스트뷰에 mutableAttrStr 대입
        textView.attributedText = mutableAttrString
        
        //Compose버튼 눌렀을 때, 제목 폰트가 이어받아지는 경우가 있어 이를 막기 위한 코드
        if mutableAttrString.length == 0 {
            textView.typingAttributes = FormAttribute.defaultAttr
        }
    }
    
    internal func saveToDataSource() {
        guard let attrText = textView.attributedText,
            let indexPath = blockTableVC?.tableView.indexPath(for: self),
            let vc = blockTableVC else { return }
        
        
        let mutableAttrString = NSMutableAttributedString(attributedString: attrText)
        
        //1. 피아노 효과부터 :: ::를 삽입해준다.
        var highlightRanges: [NSRange] = []
        mutableAttrString.enumerateAttribute(.backgroundColor, in: NSRange(location: 0, length: mutableAttrString.length), options: .reverse) { (value, range, _) in
            guard let color = value as? Color,
                color == Color.highlight else { return }
            highlightRanges.append(range)
        }
        
        //reverse로 진행된 것이므로, 순차 탐색하면서 :: 넣어주면 된다.
        highlightRanges.forEach {
            mutableAttrString.replaceCharacters(in: NSRange(location: $0.upperBound, length: 0), with: "::")
            mutableAttrString.replaceCharacters(in: NSRange(location: $0.lowerBound, length: 0), with: "::")
        }
        
        
        
        //2. 버튼에 있는 걸 키로 만들어 삽입해준다.
        if let headerStr = headerButton.title(for: .normal) {
            let attrString = NSAttributedString(string: headerStr)
            mutableAttrString.insert(attrString, at: 0)
        } else if let formStr = formButton.title(for: .normal), let bulletValue = PianoBullet(type: .value, text: formStr, selectedRange: NSRange(location: 0, length: 0)) {
            let attrString = NSAttributedString(
                string: bulletValue.whitespaces.string + bulletValue.key + bulletValue.followStr)
            mutableAttrString.insert(attrString, at: 0)
        }
        
        vc.dataSource[indexPath.section][indexPath.row] = mutableAttrString.string
    }

}

extension BlockTableViewCell {
    //필요 시 취소선을 입혀주는 로직
//    internal func addCheckAttrIfNeeded() {
//        guard textView.attributedText.length != 0 else { return }
//        
//        let isOn = PianoBullet(type: .value, text: formButton.title(for: .normal), selectedRange: <#T##NSRange#>)
//    }
}
