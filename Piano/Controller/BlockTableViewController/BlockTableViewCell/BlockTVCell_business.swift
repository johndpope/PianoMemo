//
//  BlockTVCell_business.swift
//  Piano
//
//  Created by Kevin Kim on 21/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension BlockTableViewCell {
    internal func setupDelegate() {
        textView.delegate = self
    }
    
    internal func setup(string: String) {
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
    
    //MARK: textShouldChange
    //서식 취소
    internal func revertForm() {
        
        if let header = headerButton.title(for: .normal),
            let headerKey = HeaderKey(
                text: header,
                selectedRange: NSRange(location: 0, length: 0)) {
            //헤더가 있을 때
            
            //1. 버튼 리셋시키고, 히든시킨다.
            headerButton.setTitle(nil, for: .normal)
            headerButton.isHidden = true
            
            //2. 텍스트 뷰 앞에 키를 넣어준다.
            let frontString = headerKey.whitespaces.string + headerKey.string
            let frontAttrString = NSAttributedString(
                string: frontString,
                attributes: FormAttribute.defaultAttr)
            textView.replaceCharacters(
                in: NSRange(location: 0, length: 0),
                with: frontAttrString)
            textView.textStorage.addAttributes(
                FormAttribute.defaultAttr,
                range: NSRange(
                    location: 0,
                    length: textView.attributedText.length))
            
        } else if let form = formButton.title(for: .normal),
            let bulletValue = PianoBullet(type: .value, text: form, selectedRange: NSRange(location: 0, length: 0)) {
            //서식이 있을 때
            
            //1. 버튼 리셋시키고, 히든시킨다.
            formButton.setTitle(nil, for: .normal)
            formButton.isHidden = true
            
            //2. 텍스트뷰 앞에 키를 넣어준다.
            let frontString = bulletValue.whitespaces.string + (bulletValue.isOrdered
                ? bulletValue.userDefineForm.shortcut + "."
                : bulletValue.userDefineForm.shortcut)
            let frontAttrString = NSAttributedString(
                string: frontString,
                attributes: FormAttribute.defaultAttr)
            textView.replaceCharacters(
                in: NSRange(location: 0, length: 0),
                with: frontAttrString)
            
            if bulletValue.isOn {
                textView.textStorage.addAttributes(
                    FormAttribute.defaultAttr,
                    range: NSRange(
                        location: 0,
                        length: textView.attributedText.length))
            }
        }
    }
    
    //MARK: textViewDidChange
    //필요 시 취소선을 입혀주는 로직
    internal func addCheckAttrIfNeeded() {
        guard textView.attributedText.length != 0 else { return }
        
        //nil일 때는 isOn = false로 처리해서 하단에 로직을 묶어줌.
        let isOn = PianoBullet(
            type: .value,
            text: formButton.title(for: .normal) ?? "",
            selectedRange: NSRange(location: 0, length: 0))?
            .isOn ?? false
        
        let index = textView.attributedText.length - 1
        let style = textView.attributedText.attribute(
            .strikethroughStyle, at: index,
            effectiveRange: nil) as? Int
        
        
        if isOn && (style == nil || style == 0) {
            let range = NSRange(
                location: 0,
                length: textView.attributedText.length)
            
            textView.textStorage.addAttributes(
                FormAttribute.strikeThroughAttr,
                range: range)
            return
        }
        
        //nil이거나, 체크가 아닌데도 불구하고 스타일이 1일 때
        if !isOn && (style == 1) {
            let range = NSRange(
                location: 0,
                length: textView.attributedText.length)
            
            textView.textStorage.addAttributes(
                FormAttribute.defaultAttr,
                range: range)
            return
        }
    }
    
    //필요시 헤더를 입혀주는 로직(textViewDidChange)
    internal func addHeaderAttrIfNeeded() {
        guard textView.attributedText.length != 0,
            let vc = blockTableVC,
            let headerTitle = headerButton.title(for: .normal),
            let headerKey = HeaderKey(
                text: headerTitle,
                selectedRange: NSRange(location: 0, length: 0)) else { return }
        
        //폰트 자체는 언어 지원에 따라 다를 수 있으므로, 폰트 사이즈로 비교한다.
        if let font = textView.attributedText.attribute(
            .font,
            at: 0,
            effectiveRange: nil) as? Font,
            font.pointSize != headerKey.font.pointSize {
            let range = NSRange(
                location: 0,
                length: textView.attributedText.length)
            
            textView.textStorage.addAttributes(
                [.font : headerKey.font],
                range: range)
            
            View.performWithoutAnimation {
                vc.tableView.performBatchUpdates(nil, completion: nil)
            }
        }
    }
    
    //체크리스트 개행 시에 체크를 꺼주는 역할
    internal func convertCheckOffIfNeeded() {
        guard let text = formButton.title(for: .normal),
            let bulletValue = PianoBullet(
                type: .value,
                text: text,
                selectedRange: NSRange(location: 0, length: 0)),
            bulletValue.isOn else { return }
        
        let newText = (text as NSString).replacingCharacters(
            in: bulletValue.range,
            with: bulletValue.userDefineForm.valueOff)
        formButton.setTitle(newText, for: .normal)
    }
    
    //단축키를 밸류로 바꿔줌
    internal func convert(bulletShortcut: PianoBullet) {
        let range = NSRange(
            location: 0,
            length: bulletShortcut.baselineIndex)
        let attrString = NSAttributedString(
            string: "",
            attributes: FormAttribute.defaultAttr)
        textView.replaceCharacters(in: range, with: attrString)
        setFormButton(pianoBullet: bulletShortcut)
        //서식이 체크 on일 경우 attr입혀주기
        if bulletShortcut.isOn {
            let range = NSRange(
                location: 0,
                length: textView.attributedText.length)
            textView.textStorage.addAttributes(
                FormAttribute.strikeThroughAttr,
                range: range)
        }
    }
    
    //orderedList일 경우 숫자를 맞춰주기 위해 쓰인다.
    internal func setFormButton(pianoBullet: PianoBullet?) {
        guard let pianoBullet = pianoBullet else {
            formButton.setTitle(nil, for: .normal)
            formButton.isHidden = true
            return
        }
        formButton.isHidden = false
        let fullStr = pianoBullet.whitespaces.string + pianoBullet.value + (pianoBullet.isOrdered ? ". " : " ")
        formButton.setTitle(fullStr, for: .normal)
    }
    
    internal func convert(headerKey: HeaderKey) {
        let range = NSRange(location: 0, length: headerKey.baselineIndex)
        let attrStr = NSAttributedString(string: "", attributes: FormAttribute.defaultAttr)
        textView.replaceCharacters(in: range, with: attrStr)
        setHeaderButton(headerKey: headerKey)
    }
    
    internal func setHeaderButton(headerKey: HeaderKey) {
        let fullStr = headerKey.whitespaces.string + headerKey.string + " "
        headerButton.setTitle(fullStr, for: .normal)
        headerButton.isHidden = false
    }
    
    //서식 제거
    internal func removeForm() {
        //1. 버튼을 제거하고, 히든시킨다.
        headerButton.setTitle(nil, for: .normal)
        headerButton.isHidden = true
        formButton.setTitle(nil, for: .normal)
        formButton.isHidden = true
        textView.delegate?.textViewDidChange?(textView)
    }
    
    internal func toggleCheckIfNeeded(button: Button) {
        let range = NSRange(location: 0, length: 0)
        guard let formStr = button.title(for: .normal),
            let bulletValue = PianoBullet(
                type: .value,
                text: formStr,
                selectedRange: range),
            !bulletValue.isOrdered else { return }
        
        let toggledStr = bulletValue.isOn
            ? bulletValue.userDefineForm.valueOff
            : bulletValue.userDefineForm.valueOn
        let fullStr = (formStr as NSString).replacingCharacters(in: bulletValue.range, with: toggledStr)
        
        button.setTitle(fullStr, for: .normal)
        let toggledAttr = bulletValue.isOn
            ? FormAttribute.defaultAttr
            : FormAttribute.strikeThroughAttr
        let textRange = NSRange(
            location: 0,
            length: textView.attributedText.length)
        textView.textStorage.addAttributes(
            toggledAttr,
            range: textRange)
        
        saveToDataSource()
    }
    
    enum TypingSituation {
        case revertForm
        case removeForm
        case combine
        case stayCurrent
        case split
    }
    
    internal func typingSituation(cell: BlockTableViewCell,
                                 indexPath: IndexPath,
                                 selectedRange: NSRange,
                                 replacementText text: String) -> TypingSituation {
        
        if selectedRange == NSRange(location: 0, length: 0) {
            //문단 맨 앞에 커서가 있으면서 백스페이스 눌렀을 때
            if cell.formButton.title(for: .normal) != nil || cell.headerButton.title(for: .normal) != nil {
                //서식이 존재한다면
                if text.count == 0 {
                    return .revertForm
                } else if text == "\n" {
                    return .removeForm
                } else {
                    return .stayCurrent
                }
            }
            
            if indexPath.row != 0, text.count == 0 {
                //TODO: 나중에 텍스트가 아닌 다른 타입일 경우에 이전 셀이 텍스트인 지도 체크해야함
                return .combine
            }
            
            if text == "\n" {
                return .split
            }
            
            //그 외의 경우
            return .stayCurrent
            
        } else if text == "\n" {
            //개행을 눌렀을 때
            return .split
        } else {
            return .stayCurrent
        }
    }
    
    //데이터소스에 저장할 때, 서식 사항들은 키 값으로 변환시켜야한다(헤더, 서식, 피아노효과).
    internal func split() {
        guard let vc = blockTableVC,
            let indexPath = vc.tableView.indexPath(for: self) else { return }
        let insertRange = NSRange(location: 0,
                                  length: textView.selectedRange.lowerBound)
        let insertAttrStr = textView.attributedText.attributedSubstring(from: insertRange)
        let insertMutableAttrStr = NSMutableAttributedString(attributedString: insertAttrStr)
        
        //1. 피아노 효과부터 :: ::를 삽입해준다.
        var highlightRanges: [NSRange] = []
        let mutableRange = NSRange(location: 0, length: insertMutableAttrStr.length)
        insertMutableAttrStr.enumerateAttribute(.backgroundColor, in: mutableRange, options: .reverse) { (value, range, _) in
            guard let color = value as? Color, color == Color.highlight else { return }
            highlightRanges.append(range)
        }
        
        //reverse로 했으므로 순차 탐색하면서 :: 넣어주면 된다.
        highlightRanges.forEach {
            insertMutableAttrStr.replaceCharacters(in: NSRange(location: $0.upperBound, length: 0), with: "::")
            insertMutableAttrStr.replaceCharacters(in: NSRange(location: $0.lowerBound, length: 0), with: "::")
        }
        
        //2. 버튼에 있는 걸 키로 만들어 삽입해준다.
        if let headerStr = headerButton.title(for: .normal) {
            let attrString = NSAttributedString(string: headerStr)
            insertMutableAttrStr.insert(attrString, at: 0)
            headerButton.setTitle(nil, for: .normal)
            headerButton.isHidden = true
            let textViewRange = NSRange(
                location: 0,
                length: textView.attributedText.length)
            textView.textStorage.addAttributes(
                FormAttribute.defaultAttr,
                range: textViewRange)
            
        } else if let formStr = formButton.title(for: .normal),
            var bulletValue = PianoBullet(
                type: .value,
                text: formStr,
                selectedRange: NSRange(location: 0, length: 0)) {
            let attrString = NSAttributedString(
                string: bulletValue.whitespaces.string + bulletValue.key + bulletValue.followStr)
            insertMutableAttrStr.insert(attrString, at: 0)
            
            //3. 버튼에 있는 게 순서 있는 서식이면, 현재 버튼의 숫자를 +1 해주고, 다음 서식들도 업데이트 해줘야 한다.
            if let currentNum = Int(bulletValue.value) {
                let nextNumStr = "\(UInt(currentNum + 1))"
                bulletValue.value = nextNumStr
                setFormButton(pianoBullet: bulletValue)
                adjustAfter(currentIndexPath: indexPath, pianoBullet: bulletValue)
            }
        }
        vc.dataSource[indexPath.section].insert(
            insertMutableAttrStr.string,
            at: indexPath.row)
        //4. 테이블 뷰에 삽입된 데이터 보여주기
        View.performWithoutAnimation {
            vc.tableView.insertRows(
                at: [indexPath],
                with: .none)
        }
        
        //checkOn이면, checkOff로 바꿔주기
        convertCheckOffIfNeeded()
        
        //현재 셀의 텍스트뷰의 어트리뷰트는 디폴트 어트리뷰트로 세팅하여야 함
        let leaveRange = NSRange(
            location: textView.selectedRange.upperBound,
            length: textView.attributedText.length - textView.selectedRange.upperBound)
        let leaveAttrStr = textView.attributedText.attributedSubstring(from: leaveRange)
        let leaveMutableAttrStr = NSMutableAttributedString(attributedString: leaveAttrStr)
        let range = NSRange(location: 0, length: textView.attributedText.length)
        leaveMutableAttrStr.addAttributes(FormAttribute.defaultAttr, range: NSRange(location: 0, length: leaveAttrStr.length))
        textView.replaceCharacters(in: range, with: leaveMutableAttrStr)
        textView.selectedRange = NSRange(location: 0, length: 0)
        textView.typingAttributes = FormAttribute.defaultAttr
    }
    
    // -> 이건 해동 로직이나 마찬가지임. didSet과 재사용할 수 있는 지 고민해보기
    internal func combine() {
        guard let vc = blockTableVC,
            let indexPath = vc.tableView.indexPath(for: self) else { return }
        //이전 셀의 텍스트뷰 정보를 불러와서 폰트값을 세팅해줘야 하고, 텍스트를 더해줘야한다.(이미 커서가 앞에 있으니 걍 텍스트뷰의 replace를 쓰면 된다 됨), 서식이 있다면 마찬가지로 서식을 대입해줘야한다. 서식은 텍스트 대입보다 뒤에 대입을 해야, 취소선 등이 적용되게 해야한다.
        let prevIndexPath = IndexPath(row: indexPath.row - 1, section: indexPath.section)
        let prevStr = vc.dataSource[prevIndexPath.section][prevIndexPath.row]
        
        //1. 이전 텍스트에서 피아노 효과부터 입히기
        let mutableAttrString = NSMutableAttributedString(string: prevStr, attributes: FormAttribute.defaultAttr)
        while true {
            guard let highlightKey = HighlightKey(text: mutableAttrString.string, selectedRange: NSRange(location: 0, length: mutableAttrString.length)) else { break }
            
            mutableAttrString.addAttributes([.backgroundColor: Color.highlight], range: highlightKey.range)
            mutableAttrString.replaceCharacters(in: highlightKey.endDoubleColonRange, with: "")
            mutableAttrString.replaceCharacters(in: highlightKey.frontDoubleColonRange, with: "")
        }
        
        //2. 이전 인덱스의 데이터 소스 및 셀을 지운다.
        vc.dataSource[prevIndexPath.section].remove(at: prevIndexPath.row)
        View.performWithoutAnimation {
            vc.tableView.deleteRows(
                at: [prevIndexPath],
                with: .none)
        }
        
        //3. 텍스트를 붙여준다.
        let attrTextLength = textView.attributedText.length
        mutableAttrString.append(textView.attributedText)
        
        //4. 커서를 배치시킨 다음 서식이 잘릴 것을 예상해서 replaceCharacters를 호출한다.
        let range = NSRange(location: 0, length: 0)
        if let pianoBullet = PianoBullet(
            type: .key,
            text: mutableAttrString.string, selectedRange: range) {
            let attrString = NSAttributedString(
                string: pianoBullet.userDefineForm.shortcut,
                attributes: FormAttribute.defaultAttr)
            mutableAttrString.replaceCharacters(
                in: pianoBullet.range,
                with: attrString)
        }
        let fullRange = NSRange(
            location: 0,
            length: attrTextLength)
        textView.replaceCharacters(
            in: fullRange,
            with: mutableAttrString)
        textView.selectedRange = NSRange(
            location: textView.attributedText.length - attrTextLength,
            length: 0)
    }
    
    internal func adjustAfter(currentIndexPath: IndexPath, pianoBullet: PianoBullet) {
        guard let vc = blockTableVC else { return }
        var pianoBullet = pianoBullet
        var nextIndexPath = IndexPath(
            row: currentIndexPath.row + 1,
            section: currentIndexPath.section)
        while nextIndexPath.row < vc.tableView.numberOfRows(inSection: nextIndexPath.section) {
            let str = vc.dataSource[nextIndexPath.section][nextIndexPath.row]
            let range = NSRange(location: 0, length: 0)
            guard let nextBulletKey = PianoBullet(
                type: .key,
                text: str,
                selectedRange: range),
                pianoBullet.whitespaces.string == nextBulletKey.whitespaces.string,
                let currentNum = UInt(pianoBullet.value),
                nextBulletKey.isOrdered,
                !pianoBullet.isSequencial(next: nextBulletKey) else { return }
            //check overflow
            let nextNumStr = "\(currentNum + 1)"
            pianoBullet.value = nextNumStr
            guard !pianoBullet.isOverflow else { return }
            //set dataSource
            let newStr = (str as NSString).replacingCharacters(
                in: nextBulletKey.range,
                with: nextNumStr)
            vc.dataSource[nextIndexPath.section][nextIndexPath.row] = newStr
            //set view
            if let cell = vc.tableView.cellForRow(at: nextIndexPath) as? BlockTableViewCell {
                cell.setFormButton(pianoBullet: pianoBullet)
            }
            nextIndexPath.row += 1
        }
    }
    
    internal func adjust(prevIndexPath: IndexPath, for bulletKey: PianoBullet) -> PianoBullet {
        //이전 셀이 존재하고, 그 셀이 ordered이고, whitespace까지 같다면,  그 셀의 숫자 값 + 1한 값을 bulletKey의 value에 대입
        guard let vc = blockTableVC else { return bulletKey }
        let str = vc.dataSource[prevIndexPath.section][prevIndexPath.row]
        let range = NSRange(location: 0, length: 0)
        guard let prevBulletKey = PianoBullet(type: .key, text: str, selectedRange: range),
            let num = UInt(prevBulletKey.value),
            prevBulletKey.whitespaces.string == bulletKey.whitespaces.string else { return bulletKey }
        var bulletKey = bulletKey
        bulletKey.value = "\(num + 1)"
        return bulletKey
    }
    
    internal func layoutCellIfNeeded(_ textView: TextView) {
        guard let vc = blockTableVC else { return }
        let index = textView.attributedText.length - 1
        guard index > -1 else {
            View.performWithoutAnimation {
                vc.tableView.performBatchUpdates(nil, completion: nil)
            }
            return
        }
        
        let lastLineRect = textView.layoutManager.lineFragmentRect(
            forGlyphAt: index,
            effectiveRange: nil)
        let textViewHeight = textView.bounds.height
        //TODO: 테스트해보면서 20값 해결하기
        guard textView.layoutManager.location(forGlyphAt: index).y == 0
            || textViewHeight - (lastLineRect.origin.y + lastLineRect.height) > 20 else { return }
        
        View.performWithoutAnimation {
            vc.tableView.performBatchUpdates(nil, completion: nil)
        }
    }
    
    internal func layoutCell() {
        guard let vc = blockTableVC else { return }
        View.performWithoutAnimation {
            vc.tableView.performBatchUpdates(nil, completion: nil)
        }
    }
}
