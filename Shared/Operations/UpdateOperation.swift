//
//  UpdateOperation.swift
//  Piano
//
//  Created by hoemoon on 09/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

class UpdateOperation: Operation, RecordProvider {
    private let originNote: Note
    private let context: NSManagedObjectContext
    private let string: String?
    private let newAttributedString: NSAttributedString?
    private let isRemoved: Bool?
    private let isLocked: Bool?
    private let changedTags: String?
    private let needUpdateDate: Bool
    private let isShared: Bool?
    private let completion: () -> Void

    var recordsToSave: Array<RecordWrapper>? = nil
    var recordsToDelete: Array<RecordWrapper>? = nil

    init(note origin: Note,
         context: NSManagedObjectContext,
         attributedString: NSAttributedString? = nil,
         string: String? = nil,
         isRemoved: Bool? = nil,
         isLocked: Bool? = nil,
         changedTags: String? = nil,
         needUpdateDate: Bool = true,
         isShared: Bool? = nil,
         completion: @escaping () -> Void) {

        self.originNote = origin
        self.context = context
        self.changedTags = changedTags
        self.newAttributedString = attributedString
        self.string = string
        self.isRemoved = isRemoved
        self.isLocked = isLocked
        self.needUpdateDate = needUpdateDate
        self.isShared = isShared
        self.completion = completion
        super.init()
    }

    override func main() {
        context.performAndWait {
            if let isRemoved = isRemoved {
                originNote.isRemoved = isRemoved
            } else if let newAttributedString = newAttributedString {

                let str = newAttributedString.deformatted
                let (title, subTitle) = str.titles
                originNote.title = title
                originNote.subTitle = subTitle
                originNote.content = str

            } else if let string = string {
                let (title, subTitle) = string.titles
                originNote.title = title
                originNote.subTitle = subTitle
                originNote.content = string
            } else if let isLocked = isLocked {
                var str = originNote.tags ?? ""
                str.removeCharacters(strings: [Preference.lockStr])
                if isLocked {
                    str.append(Preference.lockStr)
                }
                originNote.tags = str
                originNote.isLocked = isLocked
            } else if let changedTags = changedTags {
                originNote.tags = changedTags
                let isLocked = changedTags.contains(Preference.lockStr)
                originNote.isLocked = isLocked
            } else if let isShared = isShared {
                originNote.isShared = isShared
            }
            if needUpdateDate {
                originNote.modifiedAt = Date()
            }
            recordsToSave = [originNote.recodify()]
            context.saveIfNeeded()       
        }
        completion()
    }
}
