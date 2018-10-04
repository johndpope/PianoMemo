//
//  Note_extension.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 30..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import EventKit
import Contacts
import ContactsUI
import Photos
import DifferenceKit

struct NoteAttributes: Codable {
    let highlightRanges: [NSRange]
}

extension NoteAttributes: Equatable {
    static func == (lhs: NoteAttributes, rhs: NoteAttributes) -> Bool {
        if lhs.highlightRanges.count != rhs.highlightRanges.count {
            return false
        }
        for index in 0..<lhs.highlightRanges.count {
            if lhs.highlightRanges[index] != rhs.highlightRanges[index] {
                return false
            }
        }
        return true
    }
}

extension Note {
    var atttributes: NoteAttributes? {
        get {
            guard let attributeData = attributeData else { return nil }
            return try? JSONDecoder().decode(NoteAttributes.self, from: attributeData)
        } set {
            let data = try? JSONEncoder().encode(newValue)
            attributeData = data
        }
    }
}


extension Note {
    
    
    /**
     코어데이터에 저장하는 로직
     1. key로 치환
     2. highlight range 저장
     3. key로 치환된 text 저장
     */
    internal func save(from attrString: NSAttributedString) {
        guard let context = managedObjectContext else { return }
        
        context.performAndWait {
            var range = NSMakeRange(0, 0)
            let mutableAttrString = NSMutableAttributedString(attributedString: attrString)
            
            //1.
            while true {
                guard range.location < mutableAttrString.length else { break }
                let paraRange = (mutableAttrString.string as NSString).paragraphRange(for: range)
                range.location = paraRange.location + paraRange.length + 1
                
                guard let bulletValue = BulletValue(text: mutableAttrString.string, selectedRange: paraRange)
                    else { continue }
                
                mutableAttrString.replaceCharacters(in: bulletValue.range, with: bulletValue.key)
            }
            
            //2.
            var ranges: [NSRange] = []
            mutableAttrString.enumerateAttribute(.backgroundColor, in: NSMakeRange(0, mutableAttrString.length), options: .longestEffectiveRangeNotRequired) { (value, range, _) in
                guard let backgroundColor = value as? Color, backgroundColor == Color.highlight else { return }
                ranges.append(range)
            }
            
            self.atttributes = NoteAttributes(highlightRanges: ranges)
            self.content = mutableAttrString.string
            self.modifiedAt = Date()
            context.saveIfNeeded()
        }
        
    }
    
    /**
     1. 클라우드에서 오면 enumerate 돌아 range 입힘
     2. key를 value로 치환 (transformToValue)
     */
    internal func load() -> NSAttributedString {
        guard let content = content else {
            return NSAttributedString(string: "", attributes: Preference.defaultAttr)
        }
        
        let mutableAttrString = NSMutableAttributedString(string: content, attributes: Preference.defaultAttr)
        
        if let ranges = atttributes?.highlightRanges {
            ranges.forEach {
                mutableAttrString.addAttributes([.backgroundColor : Color.highlight], range: $0)
            }
        }
        
        var range = NSMakeRange(0, 0)
        while true {
            guard range.location < mutableAttrString.length else { break }
            
            let paraRange = (mutableAttrString.string as NSString).paragraphRange(for: range)
            range.location = paraRange.location + paraRange.length + 1
            
            if let bulletKey = BulletKey(text: mutableAttrString.string, selectedRange: paraRange) {
                range.location += mutableAttrString.transform(bulletKey: bulletKey)
                continue
            }
            
            if let bulletValue = BulletValue(text: mutableAttrString.string, selectedRange: paraRange) {
                mutableAttrString.transform(bulletValue: bulletValue)
                continue
            }
        }
        
        return mutableAttrString
    }
}

extension Note: Differentiable {
    public var differenceIdentifier: Int {
        return (self.content?.hashValue ?? 0) + (self.recordArchive?.hashValue ?? 0)
    }

    public func isContentEqual(to source: Note) -> Bool {
        if let a = self.recordArchive, let b = source.recordArchive {
            return a == b && self.content == source.content
        }
        return self.content == source.content
    }
}
