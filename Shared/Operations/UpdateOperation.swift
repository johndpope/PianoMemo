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
    private let backgroundContext: NSManagedObjectContext
    private let mainContext: NSManagedObjectContext
    private let string: String?
    private let isRemoved: Bool?
    private let isLocked: Bool?
    private let isPinned: Bool?
    private let changedTags: String?
    private let needUpdateDate: Bool
    private let isShared: Bool?
    private let completion: (() -> Void)?

    var recordsToSave: Array<RecordWrapper>? = nil
    var recordsToDelete: Array<RecordWrapper>? = nil

    init(note origin: Note,
         backgroudContext: NSManagedObjectContext,
         mainContext: NSManagedObjectContext,
         string: String? = nil,
         isRemoved: Bool? = nil,
         isLocked: Bool? = nil,
         isPinned: Bool? = nil,
         changedTags: String? = nil,
         needUpdateDate: Bool = true,
         isShared: Bool? = nil,
         completion: (() -> Void)?) {

        self.originNote = origin
        self.backgroundContext = backgroudContext
        self.mainContext = mainContext
        self.changedTags = changedTags
        self.string = string
        self.isRemoved = isRemoved
        self.isLocked = isLocked
        self.isPinned = isPinned
        self.needUpdateDate = needUpdateDate
        self.isShared = isShared
        self.completion = completion
        super.init()
    }

    override func main() {
        backgroundContext.performAndWait {
            if let isRemoved = isRemoved {
                originNote.isRemoved = isRemoved
            }
            if let string = string {
                let (title, subTitle) = string.titles
                originNote.title = title
                originNote.subTitle = subTitle
                originNote.content = string
            }
            if let isLocked = isLocked {
                originNote.isLocked = isLocked
            }
            if let isPinned = isPinned {
                originNote.isPinned = isPinned
            }
            if let changedTags = changedTags {
                originNote.tags = changedTags
            }
            if let isShared = isShared {
                originNote.isShared = isShared
            }
            if needUpdateDate {
                originNote.modifiedAt = Date()
            }
            recordsToSave = [originNote.recodify()]
            completion?()
            backgroundContext.saveIfNeeded()
            mainContext.saveIfNeeded()
        }
    }
}
