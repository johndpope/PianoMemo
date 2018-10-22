//
//  NSManagedObjectContext.swift
//  Piano
//
//  Created by hoemoon on 05/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CloudKit
import CoreData

extension NSManagedObjectContext {

    internal func saveIfNeeded() {
        self.performAndWait{ [weak self] in
            guard let self = self,
                self.hasChanges else { return }
            do {
                try self.save()
            } catch {
                print("컨텍스트 저장하다 에러: \(error)")
            }
        }
    }

    func note(with recordID: CKRecord.ID) -> Note? {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        let sort = NSSortDescriptor(key: "modifiedAt", ascending: false)
        request.predicate = NSPredicate(format: "%K == %@", "recordID", recordID as CVarArg)
        request.fetchLimit = 1
        request.sortDescriptors = [sort]
        if let fetched = try? fetch(request), let note = fetched.first {
            return note
        }
        return nil
    }

}


