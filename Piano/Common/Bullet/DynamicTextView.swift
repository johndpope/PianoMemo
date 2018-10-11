//
//  BulletTextView.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 7..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

open class DynamicTextView: UITextView {
    
    internal var note: Note!
    
    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.lightGray
        self.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontSizeToFitWidth = true
        let width = min(bounds.width, bounds.height) - 20
        label.widthAnchor.constraint(equalToConstant: width).isActive = true
        label.textAlignment = .center
        label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        label.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        return label
    }()

    private var displayLink: CADisplayLink?
    private var animationLayer: CAShapeLayer?

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setInset(contentInsetBottom: Preference.textViewInsetBottom)
        //For Piano
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
                note?.hasEdit = true
                return
            }
        }
        
        isEditable = true
        isSelectable = true
        selectedRange = NSMakeRange(index + 1 != attributedText.length ? index : index + 1, 0)
        becomeFirstResponder()
    }
    
   
    
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

        return super.hitTest(point, with: event)
    }
    
    open override func paste(_ sender: Any?) {
        note.hasEdit = true
        guard let string = UIPasteboard.general.string else { return }
        let attrString = string.createFormatAttrString(fromPasteboard: true)
        textStorage.replaceCharacters(in: selectedRange, with: attrString)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.selectedRange.location += attrString.length
            self.selectedRange.length = 0
            self.insertText("")
        }
    }
    
}

extension DynamicTextView {
    internal func setup(note: Note) {
        isHidden = true
        self.note = note
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let `self` = self else { return }
            let attrString = self.note.load()
            
            DispatchQueue.main.async {
                self.isHidden = false
                self.attributedText = attrString
            }
        }
        
        if let date = note.modifiedAt {
            let string = DateFormatter.sharedInstance.string(from:date)
            self.setDateLabel(text: string)
        }
    }

    //internal for HowToUse
    internal func setDateLabel(text: String) {
        label.text = text
    }
    
    @objc private func animateLayers(displayLink: CADisplayLink) {
        var ranges:[NSRange] = []
        textStorage.enumerateAttribute(.animatingBackground, in: NSMakeRange(0, textStorage.length), options: .longestEffectiveRangeNotRequired) { value, range, _ in

            if let _ = (value as? Bool) {
//                let range = range.move(offset: 1)
                ranges.append(range)
            }
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
        animationLayer?.fillRule = CAShapeLayerFillRule.nonZero

    }

    private func validateDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(animateLayers(displayLink:)))
        displayLink?.preferredFramesPerSecond = 20
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

extension UITextView {
    internal func setInset(contentInsetBottom: CGFloat) {
        if self is DynamicTextView {
            textContainerInset = EdgeInsets(top: 30, left: marginLeft, bottom: 8, right: marginRight)
            contentInset.bottom = contentInsetBottom
            scrollIndicatorInsets.bottom = contentInsetBottom
            
        } else {
            textContainerInset = EdgeInsets(top: 8, left: marginLeft, bottom: 8, right: marginRight)
        }
        
    }
}
