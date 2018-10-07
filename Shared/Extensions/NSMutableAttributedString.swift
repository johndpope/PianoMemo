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
    internal func transform(bulletValue: BulletValue) -> Int {
        var offset = 0
        guard !bulletValue.isOverflow else { return offset }
        switch bulletValue.type {
        case .orderedlist:
            addAttributes([.foregroundColor : Preference.effectColor], range: bulletValue.range)
            addAttributes([
                .foregroundColor: Preference.punctuationColor,
                .kern: Preference.punctuationAttr(num: bulletValue.string)], range: NSMakeRange(bulletValue.baselineIndex - 2, 1))
        case .checklistOff:
            //off일 경우 현재 프리퍼런스 오프로 치환해주고,
            let checklistOff = Preference.checklistOffValue
            let attrString = NSAttributedString(string: checklistOff, attributes: Preference.formAttr(form: checklistOff))
            self.replaceCharacters(in: bulletValue.range, with: attrString)
            offset = attrString.length - bulletValue.range.length
        case .checklistOn:
            let checklistOn = Preference.checklistOnValue
            let attrString = NSAttributedString(string: checklistOn, attributes: Preference.formAttr(form: checklistOn))
            self.replaceCharacters(in: bulletValue.range, with: attrString)
            offset = attrString.length - bulletValue.range.length
            
            let valueRange = NSMakeRange(bulletValue.baselineIndex + offset, bulletValue.paraRange.upperBound - bulletValue.baselineIndex)
            self.addAttributes(Preference.strikeThroughAttr, range: valueRange)
        case .firstlist:
            let firstlist = Preference.firstlistValue
            let attrString = NSAttributedString(string: firstlist, attributes: Preference.formAttr(form: firstlist))
            self.replaceCharacters(in: bulletValue.range, with: attrString)
            offset = attrString.length - bulletValue.range.length
        case .secondlist:
            let secondlist = Preference.secondlistValue
            let attrString = NSAttributedString(string: secondlist, attributes: Preference.formAttr(form: secondlist))
            self.replaceCharacters(in: bulletValue.range, with: attrString)
            offset = attrString.length - bulletValue.range.length
        case .idealist:
            let idealist = Preference.idealistValue
            let attrString = NSAttributedString(string: idealist, attributes: Preference.formAttr(form: idealist))
            self.replaceCharacters(in: bulletValue.range, with: attrString)
            offset = attrString.length - bulletValue.range.length
        }
        
        addAttributes([.paragraphStyle : Preference.paragraphStyle(
            form: bulletValue.string,
            whitespace: bulletValue.whitespaces.string,
            kern: bulletValue.type != .orderedlist ? Preference.kern(form: bulletValue.string) : Preference.kern(num: bulletValue.string))],
                      range: bulletValue.range)
        return offset
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
