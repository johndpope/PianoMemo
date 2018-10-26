//
//  BulletTextView.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 7..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

open class DynamicTextView: UITextView {
    var hasEdit: Bool = false
    internal var note: Note!
    lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.text = DateFormatter.sharedInstance.string(from: Date())
        label.textAlignment = .center
        label.textColor = Color.lightGray
        label.sizeToFit()
        self.addSubview(label)
        label.topAnchor.constraint(equalTo: self.topAnchor, constant: 8).isActive = true
        label.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        label.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        return label
    }()

    var insertedRanges = [NSRange]()

    private var displayLink: CADisplayLink?
    private var animationLayer: CAShapeLayer?

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        //For Piano
        textContainerInset.top = label.frame.maxY + 16
        textContainerInset.left = 10
        textContainerInset.right = 10
        let type = String(describing: self)
        tag = type.hashValue
        animationLayer = CAShapeLayer()
        animationLayer?.frame = self.bounds.divided(atDistance: 0.0, from: .minYEdge).remainder

        layer.insertSublayer(animationLayer!, at: 0)

        validateDisplayLink()
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        //글자수가 0이면 그냥 띄우자.
        guard text.count != 0 else {
            becomeFirstResponder()
            return
        }
        
        guard var point = touches.first?.location(in: self) else { return }
        point.y -= textContainerInset.top
        point.x -= textContainerInset.left
        let index = layoutManager.glyphIndex(for: point, in: textContainer)
        var lineRange = NSRange()
        let _ = layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
        if let bulletValue = BulletValue(text: text, selectedRange: lineRange),
            bulletValue.type == .checklistOff || bulletValue.type == .checklistOn {
            let checkPosition = layoutManager.boundingRect(forGlyphRange: bulletValue.range, in: textContainer)
            let a = checkPosition.origin.x
            let b = checkPosition.origin.x + checkPosition.size.width
            
            if a - 10 < point.x && point.x < b + 10 {
                if bulletValue.string == Preference.checklistOffValue {
                    let paraRange = bulletValue.paraRange
                    let location = bulletValue.baselineIndex
                    let length = paraRange.upperBound - location
                    let strikeThroughRange = NSMakeRange(location, length)
                    
                    textStorage.addAttributes(Preference.strikeThroughAttr, range: strikeThroughRange)
                } else if bulletValue.string == Preference.checklistOnValue {
                    let paraRange = bulletValue.paraRange
                    let location = bulletValue.baselineIndex
                    let length = paraRange.upperBound - location
                    let strikeThroughRange = NSMakeRange(location, length)
                    
                    let attr: [NSAttributedString.Key : Any] = [.strikethroughStyle : 0,
                                                                .foregroundColor : Preference.textColor]
                    textStorage.addAttributes(attr, range: strikeThroughRange)
                }
                
                
                textStorage.replaceCharacters(in: bulletValue.range, with: bulletValue.string != Preference.checklistOffValue ? Preference.checklistOffValue : Preference.checklistOnValue)
                layoutManager.invalidateDisplay(forGlyphRange: bulletValue.range)
                
                Feedback.success()
                hasEdit = true
                delegate?.textViewDidChange?(self)
                isEditable = false
                isSelectable = false
                return
            }
        }
        
        //해당 인덱스에 링크 어트리뷰트가 존재하고, 마지막 글자가 아니라면 isEditable = true, isSelectable = false
        if let url = attributedText.attribute(.link, at: index, effectiveRange: nil) as? URL, abs(point.x - layoutManager.location(forGlyphAt: index).x) < 30 {
            Application.shared.open(url, options: [:], completionHandler: nil)
            return
        }
        
        isEditable = true
        isSelectable = true
        selectedRange = NSMakeRange(index + 1 != attributedText.length ? index : index + 1, 0)
        becomeFirstResponder()
    }
    
   //체크리스트를 터치한 거라면 hitTest에서 다 바뀌버리고 종결시켜버리자.
    //키보드가 올라와있을 때 키보드를 내려주기 위한 장치
    var hitTestCount = 0
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard subView(PianoControl.self) == nil else {
            return super.hitTest(point, with: event)
        }

        //발견되었으면
        hitTestCount += 1
        guard hitTestCount > 1, text.count != 0
            else { return super.hitTest(point, with: event) }

        var newPoint = point
        newPoint.y -= textContainerInset.top
        newPoint.x -= textContainerInset.left
        let index = layoutManager.glyphIndex(for: newPoint, in: textContainer)
        var lineRange = NSRange()
        let _ = layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
        if let bulletValue = BulletValue(text: text, selectedRange: lineRange),
            bulletValue.type == .checklistOn || bulletValue.type == .checklistOff {
            let checkPosition = layoutManager.boundingRect(forGlyphRange: bulletValue.range, in: textContainer)
            let a = checkPosition.origin.x
            let b = checkPosition.origin.x + checkPosition.size.width

            if a - 10 < point.x && point.x < b + 10 {
                isEditable = false
                isSelectable = false
                return super.hitTest(point, with: event)
            }
        }
        
        //해당 인덱스에 링크 어트리뷰트가 존재하고, 마지막 글자가 아니라면 isEditable = true, isSelectable = false
        if let _ = attributedText.attribute(.link, at: index, effectiveRange: nil) as? URL, abs(point.x - layoutManager.location(forGlyphAt: index).x) < 30 {
            isEditable = false
            isSelectable = true
            return super.hitTest(point, with: event)
        }
        
        
        
        return super.hitTest(point, with: event)
    }
    
    open override func paste(_ sender: Any?) {
        hasEdit = true
        guard let string = UIPasteboard.general.string else { return }
        let attrString = string.createFormatAttrString(fromPasteboard: true)
        replaceCharacters(in: selectedRange, with: attrString)
    }
    
//    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
//        print(sender)
//
//        return true
//    }
}

extension DynamicTextView {
    internal func setup(
        note: Note,
        completion: @escaping (NSAttributedString) -> Void) {

        self.note = note
        let label = UILabel()
        label.text = "불러오는 중..."
        label.sizeToFit()
        label.center = self.center
        addSubview(label)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let `self` = self else { return }
            let attrString = self.note.load()
            
            DispatchQueue.main.async {
                label.removeFromSuperview()
                self.attributedText = attrString
                completion(attrString)
            }
        }
    }
    
    @objc private func animateLayers(displayLink: CADisplayLink) {
        let path = UIBezierPath()
        insertedRanges.forEach { range in
            let rect = layoutManager.boundingRect(forGlyphRange: range, in: textContainer)
                .offsetBy(dx: 0, dy: textContainerInset.top)
                .offsetBy(dx: textContainerInset.left, dy: 0)

            path.append(UIBezierPath(rect: rect))
        }

        let alpha = animationLayer?.fillColor?.alpha
        if let alpha = alpha {
            if alpha <= 0 {
                displayLink.isPaused = true
                insertedRanges = []
            }
            animationLayer?.fillColor = Color.highlight.withAlphaComponent(alpha - 0.01).cgColor
        }
        animationLayer?.path = path.cgPath
        animationLayer?.fillRule = CAShapeLayerFillRule.nonZero
    }

    private func validateDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(animateLayers(displayLink:)))
        displayLink?.preferredFramesPerSecond = 0
        displayLink?.isPaused = true
        displayLink?.add(to: .main, forMode: .default)
    }

    func startDisplayLink() {
        displayLink?.isPaused = false
        animationLayer?.fillColor = UIColor.orange.cgColor
    }
}


private extension CGRect {
    var isValid: Bool {
        return !isNull && !isInfinite && !isEmpty
    }
}
