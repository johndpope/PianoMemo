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
import CloudKit

//struct NoteAttributes: Codable {
//    let highlightRanges: [NSRange]
//}
//
//extension NoteAttributes: Equatable {
//    static func == (lhs: NoteAttributes, rhs: NoteAttributes) -> Bool {
//        if lhs.highlightRanges.count != rhs.highlightRanges.count {
//            return false
//        }
//        for index in 0..<lhs.highlightRanges.count {
//            if lhs.highlightRanges[index] != rhs.highlightRanges[index] {
//                return false
//            }
//        }
//        return true
//    }
//}

//extension Note {
//    var atttributes: NoteAttributes? {
//        get {
//            guard let attributeData = attributeData else { return nil }
//            return try? JSONDecoder().decode(NoteAttributes.self, from: attributeData)
//        } set {
//            let data = try? JSONEncoder().encode(newValue)
//            attributeData = data
//        }
//    }
//}


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
//            var ranges: [NSRange] = []
//            mutableAttrString.enumerateAttribute(.foregroundColor, in: NSMakeRange(0, mutableAttrString.length), options: .longestEffectiveRangeNotRequired) { (value, range, _) in
//                guard let foregroundColor = value as? Color, foregroundColor == Color.highlight else { return }
//                ranges.append(range)
//            }
//
//            atttributes = NoteAttributes(highlightRanges: ranges)
            let str = mutableAttrString.string
            
            let (title, subTitle) = self.titles(from: str)
            
            self.title = title
            self.subTitle = subTitle
            content = str
            modifiedAt = Date()
            context.saveIfNeeded()
        }
        
    }
    
    /**
     잠금해제와 같은, 컨텐트 자체가 변화해야하는 경우에 사용되는 메서드
     중요) modifiedDate는 변화하지 않는다.
     */
    internal func save(from text: String, needUIUpdate: Bool) {
        guard let context = managedObjectContext else { return }
        context.performAndWait {
            let (title, subTitle) = self.titles(from: text)
            
            self.title = title
            self.subTitle = subTitle
            content = text
            if needUIUpdate {
                self.hasEdit = true
                self.modifiedAt = Date()
            }
            
            context.saveIfNeeded()
        }
    }
    
    private func titles(from content: String) -> (String, String) {
        var strArray = content.split(separator: "\n")
        guard strArray.count != 0 else {
            return ("Untitled".loc, "No text".loc)
        }
        let titleSubstring = strArray.removeFirst()
        var titleString = String(titleSubstring)
        titleString.removeCharacters(strings: Preference.allKeys)
        //아래 코드 버그 발생시킴 방법 고민해보기
//        let titleLimit = 50
//        if titleString.count > titleLimit {
//            titleString = (titleString as NSString).substring(with: NSMakeRange(0, titleLimit))
//        }
        
        
        var subTitleString: String = ""
        while true {
            guard strArray.count != 0 else { break }
            
            let pieceSubString = strArray.removeFirst()
            var pieceString = String(pieceSubString)
            pieceString.removeCharacters(strings: Preference.allKeys)
            subTitleString.append(pieceString)
            let titleLimit = 50
            if subTitleString.count > titleLimit {
                //아래 코드 버그 발생시킴 방법 고민해보기
//                subTitleString = (subTitleString as NSString).substring(with: NSMakeRange(0, titleLimit))
                break
            }
        }
        
        return (titleString, subTitleString.count != 0 ? subTitleString : "No text".loc)
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
        
//        if let ranges = atttributes?.highlightRanges {
//            ranges.forEach {
//                mutableAttrString.addAttributes([.foregroundColor : Color.highlight], range: $0)
//            }
//        }
        
        var range = NSMakeRange(0, 0)
        while true {
            guard range.location < mutableAttrString.length else { break }
            
            let paraRange = (mutableAttrString.string as NSString).paragraphRange(for: range)
            range.location = paraRange.location + paraRange.length + 1
            
            if let bulletKey = BulletKey(text: mutableAttrString.string, selectedRange: paraRange) {
                range.location += mutableAttrString.transform(bulletKey: bulletKey)
                continue
            }
        }
        
        return mutableAttrString
    }
}

extension Note: Differentiable {
    var wrapped: NoteWrapper {
        let content = self.content ?? ""
        return NoteWrapper(content: content, note: self)
    }
}

struct NoteWrapper {
    let content: String
    let note: Note
}

extension NoteWrapper: Differentiable {
    public var differenceIdentifier: Note {
        return note
    }

    public func isContentEqual(to source: NoteWrapper) -> Bool {
        return self.content == source.content
    }
}

extension Note {
    var isShared: Bool {
        if let archive = self.recordArchive,
            let record = archive.ckRecorded {
            return record.share != nil
        }
        return false
    }

    var isLocked: Bool {
        if let content = content {
            return content.contains(Preference.lockStr)
        }
        return false
    }

    var isMine: Bool? {
        if let ownerID = ownerID as? CKUserIdentity,
            let currentUserID = UserDefaults.getUserIdentity() {

            return ownerID.userRecordID! == currentUserID.userRecordID!
        }
        return nil
    }
}
