//
//  UpdateOperation.swift
//  Piano
//
//  Created by hoemoon on 09/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit

class UpdateOperation: Operation, RecordProvider {
    private let originNote: Note
    private let string: String?
    private let newAttributedString: NSAttributedString?
    private let isTrash: Bool?
    private let needUIUpdate: Bool

    var recordsToSave: Array<CKRecord>?
    var recordsToDelete: Array<CKRecord>?

    init(note origin: Note,
         attributedString: NSAttributedString? = nil,
         string: String? = nil,
         isTrash: Bool? = nil,
         needUIUpdate: Bool = true) {
        self.originNote = origin
        self.newAttributedString = attributedString
        self.string = string
        self.isTrash = isTrash
        self.needUIUpdate = needUIUpdate
        super.init()
    }

    override func main() {
        guard let context = originNote.managedObjectContext else { return }
        if let isTrash = isTrash {
            context.performAndWait {
                originNote.isTrash = isTrash
                originNote.modifiedAt = Date()
            }
        } else if let newAttributedString = newAttributedString {
            var range = NSMakeRange(0, 0)
            let mutableAttrString = NSMutableAttributedString(attributedString: newAttributedString)

            while true {
                guard range.location < mutableAttrString.length else { break }
                let paraRange = (mutableAttrString.string as NSString).paragraphRange(for: range)
                range.location = paraRange.location + paraRange.length + 1

                guard let bulletValue = BulletValue(text: mutableAttrString.string, selectedRange: paraRange)
                    else { continue }

                mutableAttrString.replaceCharacters(in: bulletValue.range, with: bulletValue.key)
            }

            let str = mutableAttrString.string
            let (title, subTitle) = str.titles

            context.performAndWait {
                originNote.title = title
                originNote.subTitle = subTitle
                originNote.content = str
                originNote.modifiedAt = Date()
                originNote.hasEdit = false
            }

        } else if let string = string {
            let (title, subTitle) = string.titles
            originNote.title = title
            originNote.subTitle = subTitle
            originNote.content = string

            if needUIUpdate {
                originNote.hasEdit = true
                originNote.modifiedAt = Date()
            }
        }
        recordsToSave = [originNote.recodify()]
        context.saveIfNeeded()
    }
}
