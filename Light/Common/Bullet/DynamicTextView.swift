//
//  BulletTextView.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 7..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

open class DynamicTextView: UITextView {
    private var label: UILabel!
    internal var hasEdit: Bool = false
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.lightGray
        addSubview(label)
        
        //For Piano
        let type = String(describing: self)
        tag = type.hashValue
        textContainerInset.left = 10
        textContainerInset.right = 10
        textContainerInset.top = 30
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
            bulletValue.type == .checklist {
            let checkPosition = layoutManager.boundingRect(forGlyphRange: bulletValue.range, in: textContainer)
            let a = checkPosition.origin.x
            let b = checkPosition.origin.x + checkPosition.size.width
            
            if a - 10 < point.x && point.x < b + 10 {
                if bulletValue.string == Preference.checkOffValue {
                    let paraRange = (self.text as NSString).paragraphRange(for: bulletValue.range)
                    let location = bulletValue.baselineIndex
                    let length = paraRange.upperBound - location
                    let strikeThroughRange = NSMakeRange(location, length)
                    
                    let attr: [NSAttributedString.Key : Any] = [.strikethroughStyle : 1,
                                                                .foregroundColor : Preference.strikeThroughColor,
                                                                .strikethroughColor : Preference.strikeThroughColor]
                    textStorage.addAttributes(attr, range: strikeThroughRange)
                } else if bulletValue.string == Preference.checkOnValue {
                    let paraRange = (self.text as NSString).paragraphRange(for: bulletValue.range)
                    let location = bulletValue.baselineIndex
                    let length = paraRange.upperBound - location
                    let strikeThroughRange = NSMakeRange(location, length)
                    
                    let attr: [NSAttributedString.Key : Any] = [.strikethroughStyle : 0,
                                                                .foregroundColor : Preference.textColor]
                    textStorage.addAttributes(attr, range: strikeThroughRange)
                }
                
                
                textStorage.replaceCharacters(in: bulletValue.range, with: bulletValue.string != Preference.checkOffValue ? Preference.checkOffValue : Preference.checkOnValue)
                layoutManager.invalidateDisplay(forGlyphRange: bulletValue.range)
                
                Feedback.success()
                return
            }
        }
        
        isEditable = true
        isSelectable = true
        selectedRange = NSMakeRange(index + 1 != attributedText.length ? index : index + 1, 0)
        becomeFirstResponder()
        
        
    }
    
   
    
    
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
            bulletValue.type == .checklist {
            let checkPosition = layoutManager.boundingRect(forGlyphRange: bulletValue.range, in: textContainer)
            let a = checkPosition.origin.x
            let b = checkPosition.origin.x + checkPosition.size.width
            
            if a - 10 < point.x && point.x < b + 10 {
                isEditable = false
                isSelectable = false
                return super.hitTest(point, with: event)
            }
        }
        
        return super.hitTest(point, with: event)
    }
    
    open override func paste(_ sender: Any?) {
        guard let string = UIPasteboard.general.string else { return }
        textStorage.replaceCharacters(in: selectedRange, with: string.createFormatAttrString())
    }
    
}

extension DynamicTextView {
    
    internal func setDescriptionLabel(text: String) {
        label.text = text
        label.sizeToFit()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        label.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
    }
    
    @objc func animateLayers(displayLink: CADisplayLink) {
        
        //        var ranges:[NSRange] = []
        //        //        print("hiiiiiiiiiiiii")
        //
        //        textStorage.enumerateAttribute(.animatingBackground, in: NSMakeRange(0, textStorage.length), options: .longestEffectiveRangeNotRequired) { (value, range, _) in
        //            guard let _ = value as? Bool else {return}
        //            ranges.append(range)
        //        }
        //
        //        let path = UIBezierPath()
        //        ranges.forEach {
        //            let currentGlyphRange = layoutManager.glyphRange(forCharacterRange: $0, actualCharacterRange: nil)
        //            let firstLocation = layoutManager.location(forGlyphAt: currentGlyphRange.lowerBound)
        //            let firstLineFragment = layoutManager.lineFragmentRect(forGlyphAt: currentGlyphRange.lowerBound, effectiveRange: nil)
        //            let lastLocation = layoutManager.location(forGlyphAt: currentGlyphRange.upperBound)
        //
        //            let lastLineFragment = layoutManager.lineFragmentRect(forGlyphAt: currentGlyphRange.upperBound-1, effectiveRange: nil)
        //            let trimmedFirst = CGRect(origin: CGPoint(x: firstLocation.x, y: firstLineFragment.minY),
        //                                      size: CGSize(width: bounds.width - firstLocation.x - textContainerInset.right - textContainerInset.left, height: firstLineFragment.height))
        //            let trimmedLast = CGRect(origin: CGPoint(x: textContainerInset.left, y: lastLineFragment.minY),
        //                                     size: CGSize(width: lastLocation.x - textContainerInset.left, height: lastLineFragment.height))
        //
        //            if firstLineFragment == lastLineFragment {
        //                let block = trimmedFirst.intersection(trimmedLast).offsetBy(dx: 0, dy: textContainerInset.top)
        //                if block.isValid {
        //                    path.append(UIBezierPath(rect: block))
        //                    print(block)
        //                }
        //            } else {
        //                let middleRect = CGRect(origin: CGPoint(x: textContainerInset.left, y: firstLineFragment.maxY),
        //                                        size: CGSize(width: trimmedFirst.maxX - trimmedLast.minX,
        //                                                     height: lastLineFragment.minY - firstLineFragment.maxY))
        //                if trimmedFirst.isValid {
        //                    path.append(UIBezierPath(rect: trimmedFirst.offsetBy(dx: 0, dy: textContainerInset.top)))
        //                }
        //                if middleRect.isValid {
        //                    path.append(UIBezierPath(rect: middleRect.offsetBy(dx: 0, dy: textContainerInset.top)))
        //                }
        //                if trimmedLast.isValid {
        //                    path.append(UIBezierPath(rect: trimmedLast.offsetBy(dx: 0, dy: textContainerInset.top)))
        //                }
        //                print(middleRect)
        //            }
        //        }
        //        let alpha = animationLayer?.fillColor?.alpha
        //        if let alpha = alpha {
        //            if alpha <= 0 {
        //                displayLink.isPaused = true
        //                textStorage.removeAttribute(.animatingBackground, range: NSMakeRange(0, textStorage.length))
        //            }
        //            animationLayer?.fillColor = UIColor.orange.withAlphaComponent(alpha - 0.01).cgColor
        //        }
        //        animationLayer?.path = path.cgPath
        //        animationLayer?.fillRule = kCAFillRuleNonZero
        //
        //
    }
    
    //    func validateDisplayLink() {
    //        displayLink = CADisplayLink(target: self, selector: #selector(animateLayers(displayLink:)))
    //        displayLink?.preferredFramesPerSecond = 20
    //        displayLink?.isPaused = true
    //        displayLink?.add(to: .main, forMode: .defaultRunLoopMode)
    //    }
}

//extension NSAttributedStringKey {
//    public static let animatingBackground = NSAttributedStringKey(rawValue: "animatingBackground")
//}

extension CGRect {
    var isValid: Bool {
        return !isNull && !isInfinite && !isEmpty
    }
}

