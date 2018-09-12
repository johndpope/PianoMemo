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
            addAttributes([.font : Preference.numFont,
                                       .foregroundColor : Preference.effectColor], range: bulletValue.range)
            addAttributes([
                .foregroundColor: Preference.punctuationColor,
                .kern: Preference.punctuationKern], range: NSMakeRange(bulletValue.baselineIndex - 2, 1))
        default:
            addAttributes([.kern : Preference.kern(form: bulletValue.string)], range: bulletValue.range)
        }
        
        addAttributes([.paragraphStyle : bulletValue.paragraphStyle],
                                  range: bulletValue.range)
    }
}
