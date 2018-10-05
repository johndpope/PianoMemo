//
//  NSMutableAttributedString_extension.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 30..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation

extension NSMutableAttributedString {
    
    
    //붙여넣기, 세팅을 위한 변형
    internal func transform(bulletValue: BulletValue) {
        guard !bulletValue.isOverflow else { return }
        switch bulletValue.type {
        case .orderedlist:
            addAttributes([.foregroundColor : Preference.effectColor], range: bulletValue.range)
            addAttributes([
                .foregroundColor: Preference.punctuationColor,
                .kern: Preference.punctuationAttr(num: bulletValue.string)], range: NSMakeRange(bulletValue.baselineIndex - 2, 1))
        default:
            addAttributes([.kern : Preference.kern(form: bulletValue.string)], range: bulletValue.range)
            
            if bulletValue.string == Preference.checklistOnValue {
                let valueRange = NSMakeRange(bulletValue.baselineIndex, bulletValue.paraRange.upperBound - bulletValue.baselineIndex)
                self.addAttributes(Preference.strikeThroughAttr, range: valueRange)
            }
        }
        
        addAttributes([.paragraphStyle : Preference.paragraphStyle(
            form: bulletValue.string,
            whitespace: bulletValue.whitespaces.string,
            kern: bulletValue.type != .orderedlist ? Preference.kern(form: bulletValue.string) : Preference.kern(num: bulletValue.string))],
                      range: bulletValue.range)
    }
    
    
    
    
    
    internal func transform(bulletKey: BulletKey) -> Int  {
        var offset = 0
        let bullet = bulletKey
        guard !bullet.isOverflow else { return offset }
        
        switch bullet.type {
        case .orderedlist:
            //이미 입혀진 거라면 리턴
            if let kern = self
                .attributedSubstring(from: bullet.punctuationRange)
                .attribute(.kern, at: 0, effectiveRange: nil) as? Float,
                kern != 0 {
                return offset
            }
            let numRange = bullet.range
            self.addAttributes(Preference.numAttr,range: numRange)
            
            let puncRange = NSMakeRange(bullet.baselineIndex - 2, 1)
            self.addAttributes(Preference.punctuationAttr(num: bullet.string),range: puncRange)
            
        default:
            let value = bullet.value
            let attrString = NSAttributedString(string: value, attributes: Preference.formAttr(form: value))
            self.replaceCharacters(in: bullet.range, with: attrString)
            offset = attrString.length - bullet.range.length
            
            if value == Preference.checklistOnValue {
                let valueRange = NSMakeRange(bullet.baselineIndex + offset, bullet.paraRange.upperBound - bullet.baselineIndex)
                self.addAttributes(Preference.strikeThroughAttr, range: valueRange)
            }
            
        }
        
        let paraRange = NSMakeRange(bullet.paraRange.location, bullet.baselineIndex - bullet.paraRange.location)
        let paraStyle = Preference.paragraphStyle(form: bullet.value, whitespace: bullet.whitespaces.string, kern: bullet.type != .orderedlist ? Preference.kern(form: bullet.value) : Preference.kern(num: bullet.value))
        self.addAttributes([.paragraphStyle : paraStyle], range: paraRange)
        return offset
    }
}
