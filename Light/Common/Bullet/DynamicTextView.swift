//
//  BulletTextView.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 7..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

open class DynamicTextView: UITextView {
    private var label: UILabel?
    internal var hasEdit: Bool = false
    
    var displayLink: CADisplayLink?
    var animationLayer: CAShapeLayer?

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        
        let size = CGSize(width: frame.width, height: CGFloat.greatestFiniteMagnitude)
        let newContainer = NSTextContainer(size: size)
        let newLayoutManager = DynamicLayoutManager()
        let newTextStorage = DynamicTextStorage()
        
        newLayoutManager.addTextContainer(newContainer)
        newTextStorage.addLayoutManager(newLayoutManager)
        
        super.init(frame: frame, textContainer: newContainer)
        
        
        newTextStorage.textView = self
        newLayoutManager.textView = self
        self.backgroundColor = UIColor.clear
        animationLayer = CAShapeLayer()
        animationLayer?.frame = self.bounds.divided(atDistance: 0.0, from: .minYEdge).remainder
        self.layer.insertSublayer(animationLayer!, at: 0)
        
        validateDisplayLink()
        
        //For Piano
        let type = String(describing: self)
        tag = type.hashValue
        
        textContainerInset.left = 10
        textContainerInset.right = 10
        textContainerInset.top = 30
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func awakeAfter(using aDecoder: NSCoder) -> Any? {
        
        let newTextView = DynamicTextView(frame: self.frame)
        newTextView.autocorrectionType = self.autocorrectionType
        newTextView.attributedText = self.attributedText
        newTextView.backgroundColor = self.backgroundColor
        newTextView.dataDetectorTypes = self.dataDetectorTypes
        newTextView.returnKeyType = self.returnKeyType
        newTextView.keyboardAppearance = self.keyboardAppearance
        newTextView.keyboardDismissMode = self.keyboardDismissMode
        newTextView.keyboardType = self.keyboardType
        newTextView.alwaysBounceVertical = self.alwaysBounceVertical
        newTextView.translatesAutoresizingMaskIntoConstraints = false
        newTextView.font = self.font
        newTextView.textColor = self.textColor
        newTextView.text = ""
        //TODO: 아래코드는 이미 init에서 실행했으므로 제거해도되는 게 맞는 지 체크
        (newTextView.layoutManager as? DynamicLayoutManager)?.textView = self
        return newTextView
        
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
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
    override open func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        hitCount += 1
        guard let text = self.text, hitCount > 1, text.count != 0 else {
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
                textStorage.replaceCharacters(in: bulletValue.range, with: bulletValue.string != Preference.checkOffValue ? Preference.checkOffValue : Preference.checkOnValue)
                Feedback.success()
                //                selectedRange.location = bulletValue.paraRange.location + bulletValue.paraRange.length
                //Info: nil을 리턴하면 체인을 여기서 멈추기 때문에 텍스트뷰의 기본 액션을 막을 수 있다(메뉴 컨트롤러 등)
                return nil
            }
        }
        return super.hitTest(point, with: event)
    }
    

}

extension DynamicTextView {
    public func set(newAttributedString: NSAttributedString) {
        (textStorage as? DynamicTextStorage)?.set(attributedString: newAttributedString)
    }
    
    public func startDisplayLink() {
        displayLink?.isPaused = false
        //백그라운드들을 저장!
        animationLayer?.fillColor = UIColor.orange.cgColor
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
    
    @objc func animateLayers(displayLink: CADisplayLink) {
        
        var ranges:[NSRange] = []
        //        print("hiiiiiiiiiiiii")
        
        textStorage.enumerateAttribute(.animatingBackground, in: NSMakeRange(0, textStorage.length), options: .longestEffectiveRangeNotRequired) { (value, range, _) in
            guard let _ = value as? Bool else {return}
            ranges.append(range)
        }
        
        let path = UIBezierPath()
        ranges.forEach {
            let currentGlyphRange = layoutManager.glyphRange(forCharacterRange: $0, actualCharacterRange: nil)
            let firstLocation = layoutManager.location(forGlyphAt: currentGlyphRange.lowerBound)
            let firstLineFragment = layoutManager.lineFragmentRect(forGlyphAt: currentGlyphRange.lowerBound, effectiveRange: nil)
            let lastLocation = layoutManager.location(forGlyphAt: currentGlyphRange.upperBound)
            
            let lastLineFragment = layoutManager.lineFragmentRect(forGlyphAt: currentGlyphRange.upperBound-1, effectiveRange: nil)
            let trimmedFirst = CGRect(origin: CGPoint(x: firstLocation.x, y: firstLineFragment.minY),
                                      size: CGSize(width: bounds.width - firstLocation.x - textContainerInset.right - textContainerInset.left, height: firstLineFragment.height))
            let trimmedLast = CGRect(origin: CGPoint(x: textContainerInset.left, y: lastLineFragment.minY),
                                     size: CGSize(width: lastLocation.x - textContainerInset.left, height: lastLineFragment.height))
            
            if firstLineFragment == lastLineFragment {
                let block = trimmedFirst.intersection(trimmedLast).offsetBy(dx: 0, dy: textContainerInset.top)
                if block.isValid {
                    path.append(UIBezierPath(rect: block))
                    print(block)
                }
            } else {
                let middleRect = CGRect(origin: CGPoint(x: textContainerInset.left, y: firstLineFragment.maxY),
                                        size: CGSize(width: trimmedFirst.maxX - trimmedLast.minX,
                                                     height: lastLineFragment.minY - firstLineFragment.maxY))
                if trimmedFirst.isValid {
                    path.append(UIBezierPath(rect: trimmedFirst.offsetBy(dx: 0, dy: textContainerInset.top)))
                }
                if middleRect.isValid {
                    path.append(UIBezierPath(rect: middleRect.offsetBy(dx: 0, dy: textContainerInset.top)))
                }
                if trimmedLast.isValid {
                    path.append(UIBezierPath(rect: trimmedLast.offsetBy(dx: 0, dy: textContainerInset.top)))
                }
                print(middleRect)
            }
        }
        let alpha = animationLayer?.fillColor?.alpha
        if let alpha = alpha {
            if alpha <= 0 {
                displayLink.isPaused = true
                textStorage.removeAttribute(.animatingBackground, range: NSMakeRange(0, textStorage.length))
            }
            animationLayer?.fillColor = UIColor.orange.withAlphaComponent(alpha - 0.01).cgColor
        }
        animationLayer?.path = path.cgPath
        animationLayer?.fillRule = kCAFillRuleNonZero
        
        
    }
    
    func validateDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(animateLayers(displayLink:)))
        displayLink?.preferredFramesPerSecond = 20
        displayLink?.isPaused = true
        displayLink?.add(to: .main, forMode: .defaultRunLoopMode)
    }
}

extension NSAttributedStringKey {
    public static let animatingBackground = NSAttributedStringKey(rawValue: "animatingBackground")
}

extension CGRect {
    var isValid: Bool {
        return !isNull && !isInfinite && !isEmpty
    }
}

