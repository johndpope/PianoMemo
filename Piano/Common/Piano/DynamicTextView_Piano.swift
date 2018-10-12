//
//  LightTextView_Piano.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 4..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreGraphics

extension DynamicTextView {
    internal var pianoControl : PianoControl? {
        return subView(PianoControl.self)
    }
    
    internal func setupStateForPiano() {
        isEditable = false
        isSelectable = false
    }
    
    internal func cleanPiano() {
        isEditable = false
        isSelectable = true
        
        subView(PianoControl.self)?.removeFromSuperview()
    }
    
    internal func pianoTrigger(touch: Touch) -> PianoTrigger {
        return { [weak self] in
            guard let `self` = self, let info: (rect: CGRect, range: NSRange, attrString: NSAttributedString) = self.lineInfo(at: touch) else { return nil }
            
            //이미지가 존재할 경우 리턴
            guard !self.attributedText.containsAttachments(in: info.range),
                info.attrString.length != 0 else { return nil }
            
            self.addCoverView(rect: info.rect)
            self.isUserInteractionEnabled = false
            
            return self.makePianos(info: info)
        }
    }
    
    internal func endPiano(with result: [PianoResult]) {
        
        setAttributes(with: result)
        removeCoverView()
        isUserInteractionEnabled = true
    }
}

extension DynamicTextView {
    private func lineInfo(at touch: Touch) -> (CGRect, NSRange, NSAttributedString)? {
        guard attributedText.length != 0 else { return nil }
        var point = touch.location(in: self)
        point.y -= textContainerInset.top
        let index = layoutManager.glyphIndex(for: point, in: textContainer)
        var lineRange = NSRange()
        let lineRect = layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
//        let (rect, range) = exclusiveBulletArea(rect: lineRect, in: lineRange)
        let attrText = attributedText.attributedSubstring(from: lineRange)
        return (lineRect, lineRange, attrText)
    }
    
    private func exclusiveBulletArea(rect: CGRect, in lineRange: NSRange) -> (CGRect, NSRange) {
        var newRect = rect
        var newRange = lineRange
        if let bullet = BulletValue(text: text, lineRange: lineRange) {
            newRange.length = newRange.length - (bullet.baselineIndex - newRange.location)
            newRange.location = bullet.baselineIndex
            let offset = layoutManager.location(forGlyphAt: bullet.baselineIndex).x
            newRect.origin.x += offset
            newRect.size.width -= offset
        }
        return (newRect, newRange)
    }
    
    //TODO: fix miss point
    var missCoverPoint: CGFloat { return -0.2 }
    func missCharPoint(font: Font) -> CGPoint {
        if font.pointSize < 15 {
            return CGPoint(x: -0.3, y: 0.3)
        } else if font.pointSize < 16 {
            return CGPoint(x: -0.2, y: -0.1)
        } else if font.pointSize < 17 {
            return CGPoint(x: -0.2, y: 0)
        } else if font.pointSize < 18 {
            return CGPoint(x: -0.1, y: -0.3)
        } else if font.pointSize < 19 {
            return CGPoint(x: -0.2, y: 0.3)
        } else if font.pointSize < 20 {
            return CGPoint(x: -0.1, y: -0.3)
        } else {
            return CGPoint.zero
        }
    }
    
    private func makePianos(info: (CGRect, NSRange, NSAttributedString)) -> [PianoData] {
        let (rect, range, attrText) = info
        
        var offset = range.lowerBound
        return attrText.string.trimmingCharacters(in: .newlines).trimmingCharacters(in: .controlCharacters).enumerated().map(
            { (index, character) -> PianoData in
                //외부 요인에 의한 값들 반영
                //text
                let characterText = String(character)
                
                //range
                let length = characterText.utf16.count
                let characterRange = NSMakeRange(offset, length)
                
                var origin = layoutManager.location(forGlyphAt: offset)
                
                origin.y = self.textContainerInset.top + rect.origin.y - contentOffset.y - Preference.lineSpacing / 2 //- LocalPreference.lineSpacing / 2
                origin.x += self.textContainerInset.left
                if let font = self.font {
                    let missCharPoint = self.missCharPoint(font: font)
                    origin.x += missCharPoint.x
                    origin.y += missCharPoint.y
                }
                

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
        correctRect.origin.y += (textContainerInset.top + missCoverPoint)
        guard let coverView = createSubviewIfNeeded(PianoCoverView.self) else {return}
        guard let control = subView(PianoControl.self) else {return}
        coverView.backgroundColor = self.backgroundColor
        coverView.frame = correctRect
        insertSubview(coverView, belowSubview: control)
    }
    
    private func removeCoverView(){
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
            textStorage.addAttributes([.backgroundColor : Color.highlight], range: addRange)
            layoutManager.invalidateDisplay(forGlyphRange: addRange)
        }

        for eraseRange in unionEraseRange {
            textStorage.addAttributes([.backgroundColor : Color.clear], range: eraseRange)
            layoutManager.invalidateDisplay(forGlyphRange: eraseRange)
        }
        
    }
}