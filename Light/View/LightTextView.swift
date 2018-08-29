//
//  LightTextView.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

class LightTextView: UITextView {
    private var label: UILabel?


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        textContainerInset.left = 10
        textContainerInset.right = 10
        textContainerInset.top = 30
        layoutManager.delegate = self
    }
    
    internal func setDescriptionLabel(text: String) {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.lightGray
        label.text = text
        label.sizeToFit()
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        label.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        guard var point = touches.first?.location(in: self) else { return }
        point.y -= textContainerInset.top
        point.x -= textContainerInset.left
        let index = layoutManager.glyphIndex(for: point, in: textContainer)
        
        if !isEditable {
            if attributedText.attribute(.link, at: index, effectiveRange: nil) != nil
                || attributedText.attribute(.attachment, at: index, effectiveRange: nil) != nil {
                return
            } else {
                selectedRange.location = index + 1
                isEditable = true
                becomeFirstResponder()
            }
        }
    }
    
    var hitCount = 0
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        hitCount += 1
        guard hitCount > 1 else {
            return super.hitTest(point, with: event)
        }
        hitCount = 0


        var point = point
        point.y -= textContainerInset.top
        point.x -= textContainerInset.left
        let index = layoutManager.glyphIndex(for: point, in: textContainer)
        var lineRange = NSRange()
        let _ = layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
        if let bulletValue = BulletValue(text: text, selectedRange: lineRange), bulletValue.type == .checklist {
            let checkPosition = layoutManager.boundingRect(forGlyphRange: bulletValue.range, in: textContainer)
            let a = checkPosition.origin.x
            let b = checkPosition.origin.x + checkPosition.size.width
            if a < point.x && point.x < b {
                textStorage.replaceCharacters(in: bulletValue.range, with: bulletValue.string != "🙅‍♀️" ? "🙅‍♀️" : "🙆‍♀️")
//                selectedRange.location = bulletValue.paraRange.location + bulletValue.paraRange.length
                //Info: nil을 리턴하면 체인을 여기서 멈추기 때문에 텍스트뷰의 기본 액션을 막을 수 있다(메뉴 컨트롤러 등)
                return nil
            }
        }
        return super.hitTest(point, with: event)
    }
    
    override func paste(_ sender: Any?) {
        //        guard let cell = superview?.superview as? TextBlockTableViewCell,
        //            let block = cell.data as? Block,
        //            let controller = cell.controller else { return }
        //
        //        let pasteboardManager = PasteboardManager()
        //        pasteboardManager.pasteParagraphs(currentBlock: block, in: controller)
    }

}

extension LightTextView: NSLayoutManagerDelegate {
    func layoutManager(_ layoutManager: NSLayoutManager, lineSpacingAfterGlyphAt glyphIndex: Int, withProposedLineFragmentRect rect: CGRect) -> CGFloat {
        return Preference.lineSpacing
    }
}
