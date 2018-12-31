//
//  LightTextView_Piano.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 4..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreGraphics

extension BlockTextView {

    internal func cleanPiano() {
        subView(PianoControl.self)?.removeFromSuperview()
    }

    internal func pianoTrigger(touch: Touch) -> PianoTrigger {
        return { [weak self] in
            guard let `self` = self, let info: (rect: CGRect, range: NSRange, attrString: NSAttributedString) = self.lineInfo(at: touch) else { return nil }

            guard let cell = self.superview?.superview?.superview as? BlockCell,
                let tableView = cell.pianoEditorView?.tableView,
                let indexPath = tableView.indexPath(for: cell) else { return nil }
            let rect = tableView.rectForRow(at: indexPath)

            //이미지가 존재할 경우 리턴
            guard !self.attributedText.containsAttachments(in: info.range),
                info.attrString.length != 0 else { return nil }

            self.addCoverView(rect: info.rect)
            self.isUserInteractionEnabled = false

            var newRect = info.rect
            newRect.origin.y += (rect.origin.y - tableView.contentOffset.y)
            newRect.origin.x += (self.frame.origin.x + (self.superview?.frame.origin.x ?? 0) + (self.superview?.superview?.frame.origin.x ?? 0))
            var newInfo: (rect: CGRect, range: NSRange, attrString: NSAttributedString) = info
            newInfo.rect = newRect

            return self.makePianos(info: newInfo)
        }
    }

    internal func endPiano(with result: [PianoResult]) {

        guard let blockCell = superview?.superview?.superview as? BlockCell,
            let pianoEditorView = blockCell.pianoEditorView,
            let indexPath = pianoEditorView.tableView.indexPath(for: blockCell) else { return }

        setAttributes(with: result)
        removeCoverView()
        isUserInteractionEnabled = true

        var highlightRanges: [NSRange] = []
        let range = NSRange(location: 0, length: attributedText.length)
        attributedText.enumerateAttribute(.backgroundColor, in: range, options: .reverse) { (value, range, _) in
            guard let color = value as? Color, color == Color.highlight else { return }
            highlightRanges.append(range)
        }

        let mutableAttrString = NSMutableAttributedString(attributedString: attributedText)
        highlightRanges.forEach {
            mutableAttrString.replaceCharacters(in: NSRange(location: $0.upperBound, length: 0), with: "::")
            mutableAttrString.replaceCharacters(in: NSRange(location: $0.lowerBound, length: 0), with: "::")
        }

        if var formStr = blockCell.formButton.title(for: .normal) {

            if let bulletValue = PianoBullet(type: .value, text: formStr, selectedRange: NSRange(location: 0, length: 0)) {
                formStr = (formStr as NSString).replacingCharacters(in: bulletValue.range, with: bulletValue.key)
            }
            let attrStr = NSAttributedString(string: formStr)
            mutableAttrString.insert(attrStr, at: 0)

        }

        pianoEditorView.dataSource[indexPath.section][indexPath.row] = mutableAttrString.string
        pianoEditorView.hasEdit = true

    }
}

extension BlockTextView {
    private func lineInfo(at touch: Touch) -> (CGRect, NSRange, NSAttributedString)? {
        guard attributedText.length != 0 else { return nil }
        var point = touch.location(in: self)
        point.y -= textContainerInset.top
        let index = layoutManager.glyphIndex(for: point, in: textContainer)
        var lineRange = NSRange()
        let lineRect = layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
        let attrText = attributedText.attributedSubstring(from: lineRange)
        return (lineRect, lineRange, attrText)
    }

    private func makePianos(info: (CGRect, NSRange, NSAttributedString)) -> [PianoData] {
        let (rect, range, attrText) = info

        var offset = range.lowerBound
        return attrText.string.trimmingCharacters(in: .newlines).trimmingCharacters(in: .controlCharacters).enumerated().map({ (_, character) -> PianoData in
                //외부 요인에 의한 값들 반영
                //text
                let characterText = String(character)

                //range
                let length = characterText.utf16.count
                let characterRange = NSRange(location: offset, length: length)

                var origin = layoutManager.location(forGlyphAt: offset)

                origin.y = self.textContainerInset.top + rect.origin.y - contentOffset.y + 2
                origin.x += (self.textContainerInset.left + info.0.origin.x)

                //attrs
                var characterAttrs = attrText.attributes(at: offset - range.lowerBound, effectiveRange: nil)
                characterAttrs[.paragraphStyle] = nil

                let characterAttrText = NSAttributedString(string: characterText, attributes: characterAttrs)

                //rect
                let characterRect = CGRect(origin: origin, size: CGSize(width: characterAttrText.size().width, height: rect.height))

                //center
                let characterOriginCenter = CGPoint(x: characterRect.midX, y: characterRect.midY)

                offset += length

                return PianoData(charRect: characterRect, charRange: characterRange, charOriginCenter: characterOriginCenter, charText: characterText, charAttrs: characterAttrs)
        })
    }

    private func addCoverView(rect: CGRect) {
        var correctRect = rect
        correctRect.origin.y += textContainerInset.top // (textContainerInset.top + missCoverPoint)
        correctRect.size.width += 10
        correctRect.size.height += 2
        guard let coverView = createSubviewIfNeeded(PianoCoverView.self) else {return}
        guard let control = subView(PianoControl.self) else {return}
        coverView.backgroundColor = self.backgroundColor
        coverView.frame = correctRect
        insertSubview(coverView, belowSubview: control)
    }

    private func removeCoverView() {
        subView(PianoCoverView.self)?.removeFromSuperview()
    }

    private func setAttributes(with result: [PianoResult]) {
        //range를 묶어주어야 함 어떻게??

        var addRanges: [NSRange] = []
        var eraseRanges: [NSRange] = []

        result.forEach { (result) in

            if let color = result.attrs[.backgroundColor] as? Color, color == Color.highlight {
                addRanges.append(result.range)
            } else {
                eraseRanges.append(result.range)
            }

        }
        //range의 최적화 작업
        //이전거의 로케 + 랭스 = 다음꺼의 로케이션이면 이전꺼와 다음꺼를 합치기
        //이전꺼의 로케 + 랭스 != 다음꺼의 로케이션이면 분리해서 append하기
        var unionAddRange: [NSRange] = []
        addRanges.enumerated().forEach { (offset, range) in
            if offset != 0 {

                let prevRange = addRanges[offset - 1]
                if prevRange.upperBound == range.lowerBound {

                    let index = unionAddRange.count - 1
                        unionAddRange[index] = unionAddRange[index].union(range)
                } else {
                    unionAddRange.append(range)
                }

            } else {
                unionAddRange.append(range)
            }
        }

        var unionEraseRange: [NSRange] = []
        eraseRanges.enumerated().forEach { (offset, range) in
            if offset != 0 {

                let prevRange = eraseRanges[offset - 1]
                if prevRange.upperBound == range.lowerBound {

                    let index = unionEraseRange.count - 1
                    unionEraseRange[index] = unionEraseRange[index].union(range)
                } else {
                    unionEraseRange.append(range)
                }

            } else {
                unionEraseRange.append(range)
            }
        }

        for addRange in unionAddRange {
            textStorage.addAttributes([.backgroundColor: Color.highlight], range: addRange)
            layoutManager.invalidateDisplay(forGlyphRange: addRange)
        }

        for eraseRange in unionEraseRange {
            textStorage.addAttributes([.backgroundColor: Color.clear], range: eraseRange)
            layoutManager.invalidateDisplay(forGlyphRange: eraseRange)
        }

    }
}
