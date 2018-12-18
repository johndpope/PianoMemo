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
    private let isPinned: Int?
    private let changedTags: String?
    private let needUpdateDate: Bool
    private let isShared: Bool?
    private let completion: (() -> Void)?

    var recordsToSave: Array<RecordWrapper>?
    var recordsToDelete: Array<RecordWrapper>?

    init(note origin: Note,
         backgroudContext: NSManagedObjectContext,
         mainContext: NSManagedObjectContext,
         string: String? = nil,
         isRemoved: Bool? = nil,
         isLocked: Bool? = nil,
         isPinned: Int? = nil,
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
            do {
                let object = try backgroundContext.existingObject(with: originNote.objectID)
                if let note = object as? Note {

                    if let isRemoved = isRemoved {
                        note.isRemoved = isRemoved
                    }
                    if let string = string {
                        let (title, subTitle) = string.titles
                        note.title = title
                        note.subTitle = subTitle
                        note.content = string
                    }
                    //                if let isLocked = isLocked {
                    //                    note.isLocked = isLocked
                    //                }
                    if let isPinned = isPinned {
                        note.isPinned = Int64(isPinned)
                    }
                    if let changedTags = changedTags {
                        note.tags = changedTags
                    }
                    if let isShared = isShared {
                        note.isShared = isShared
                    }
                    if needUpdateDate {
                        note.modifiedAt = Date()
                    }
                    recordsToSave = [note.recodify()]
                    backgroundContext.saveIfNeeded()
                    completion?()
                    mainContext.saveIfNeeded()
                }
            } catch {
                print(error)
            }
        }
    }
}
