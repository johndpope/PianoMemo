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
    private let isRemoved: Bool?
    private let isLocked: Bool?
    private let changedTags: String?
    private let isLatest: Bool

    var recordsToSave: Array<RecordWrapper>? = nil
    var recordsToDelete: Array<RecordWrapper>? = nil

    init(note origin: Note,
         attributedString: NSAttributedString? = nil,
         string: String? = nil,
         isRemoved: Bool? = nil,
         isLocked: Bool? = nil,
         changedTags: String? = nil,
         isLatest: Bool = true) {
        self.originNote = origin
        self.changedTags = changedTags
        self.newAttributedString = attributedString
        self.string = string
        self.isRemoved = isRemoved
        self.isLocked = isLocked
        self.isLatest = isLatest
        super.init()
    }

    override func main() {
        guard let context = originNote.managedObjectContext else { return }
        context.performAndWait {
            if let isRemoved = isRemoved {
                originNote.isRemoved = isRemoved
                originNote.modifiedAt = Date()
            } else if let newAttributedString = newAttributedString {

                let str = newAttributedString.deformatted
                let (title, subTitle) = str.titles
                originNote.title = title
                originNote.subTitle = subTitle
                originNote.content = str
                originNote.modifiedAt = Date()

            } else if let string = string {
                let (title, subTitle) = string.titles
                originNote.title = title
                originNote.subTitle = subTitle
                originNote.content = string
                
                if isLatest {
                    originNote.modifiedAt = Date()
                }

                if let isLocked = isLocked {
                    originNote.isLocked = isLocked
                }
                
            }
            
            if let changedTags = changedTags {
                originNote.tags = changedTags
            }
            recordsToSave = [originNote.recodify()]
            context.saveIfNeeded()       
        }
    }
}
