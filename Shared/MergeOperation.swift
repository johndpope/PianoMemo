//
//  MergeOperation.swift
//  Piano
//
//  Created by Kevin Kim on 13/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//
import Foundation
import CloudKit
import CoreData

class MergeOperation: Operation, RecordProvider {
    private let origin: Note
    private let notesToPurge: [Note]
    private let context: NSManagedObjectContext
    
    var recordsToSave: Array<RecordWrapper> = []
    var recordsToDelete: Array<RecordWrapper> = []
    
    init(origin: Note, notesToPurge: [Note], context: NSManagedObjectContext) {
        self.origin = origin
        self.notesToPurge = notesToPurge
        self.context = context
        super.init()
    }
    
    override func main() {
        context.performAndWait {
            
            guard var content = origin.content else { return }
            
            notesToPurge.forEach {
                let noteContent = $0.content ?? ""
                if noteContent.trimmingCharacters(in: .newlines).count != 0 {
                    content.append("\n" + noteContent)
                }
            }
            
            origin.content = content
            origin.modifiedAt = Date()
            
            notesToPurge.forEach {
                context.delete($0)
            }

            context.saveIfNeeded()
        }
    }
}
