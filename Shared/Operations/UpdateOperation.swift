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
    private let completion: () -> Void

    var recordsToSave: Array<RecordWrapper>? = nil
    var recordsToDelete: Array<RecordWrapper>? = nil

    init(note origin: Note,
         attributedString: NSAttributedString? = nil,
         string: String? = nil,
         isRemoved: Bool? = nil,
         isLocked: Bool? = nil,
         changedTags: String? = nil,
         needUpdateDate: Bool = true,
         completion: @escaping () -> Void) {

        self.originNote = origin
        self.changedTags = changedTags
        self.newAttributedString = attributedString
        self.string = string
        self.isRemoved = isRemoved
        self.isLocked = isLocked
        self.isLatest = needUpdateDate
        self.completion = completion
        super.init()
    }

    override func main() {
        guard let context = originNote.managedObjectContext else { return }
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
                originNote.isLocked = isLocked
            } else if let changedTags = changedTags {
                originNote.tags = changedTags
            }
            if isLatest {
                originNote.modifiedAt = Date()
            }
            recordsToSave = [originNote.recodify()]
            context.saveIfNeeded()       
        }
        completion()
    }
}
