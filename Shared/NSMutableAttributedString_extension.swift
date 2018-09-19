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
            addAttributes([.foregroundColor : LocalPreference.effectColor], range: bulletValue.range)
            addAttributes([
                .foregroundColor: LocalPreference.punctuationColor,
                .kern: LocalPreference.punctuationAttr(num: bulletValue.string)], range: NSMakeRange(bulletValue.baselineIndex - 2, 1))
        default:
            addAttributes([.kern : LocalPreference.kern(form: bulletValue.string)], range: bulletValue.range)
            
            if bulletValue.string == LocalPreference.checkOnValue {
                let valueRange = NSMakeRange(bulletValue.baselineIndex, bulletValue.paraRange.upperBound - bulletValue.baselineIndex)
                self.addAttributes(LocalPreference.strikeThroughAttr, range: valueRange)
            }
        }
        
        addAttributes([.paragraphStyle : bulletValue.paragraphStyle],
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
            self.setAttributes(LocalPreference.numAttr,range: numRange)
            
            let puncRange = NSMakeRange(bullet.baselineIndex - 2, 1)
            self.setAttributes(LocalPreference.punctuationAttr(num: bullet.string),range: puncRange)
            
        default:
            let value = bullet.value
            let attrString = NSAttributedString(string: value, attributes: LocalPreference.formAttr(form: value))
            self.replaceCharacters(in: bullet.range, with: attrString)
            offset = attrString.length - bullet.range.length
            
            if value == LocalPreference.checkOnValue {
                let valueRange = NSMakeRange(bullet.baselineIndex + offset, bullet.paraRange.upperBound - bullet.baselineIndex)
                self.addAttributes(LocalPreference.strikeThroughAttr, range: valueRange)
            }
            
        }
        
        let paraRange = NSMakeRange(bullet.paraRange.location, bullet.baselineIndex - bullet.paraRange.location)
        self.addAttributes([.paragraphStyle : bullet.paragraphStyle], range: paraRange)
        return offset
    }
}
