//
//  FolderCollectionHeaderView.swift
//  Piano
//
//  Created by hoemoon on 01/02/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit
import CoreData

class FolderCollectionHeaderView: UICollectionReusableView {
    var context: NSManagedObjectContext?
    @IBOutlet weak var allFolderView: SystemFolderView!
    @IBOutlet weak var lockedFolderView: SystemFolderView!
    @IBOutlet weak var removedFolderView: SystemFolderView!

    func setup(delegate: SystemFolderViewDelegate, context: NSManagedObjectContext?) {
        guard let context = context else { return }
        self.context = context
        context.performAndWait {
            do {
                let noteRequest: NSFetchRequest<Note> = Note.fetchRequest()
                noteRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                        NSPredicate(format: "isLocked == false"),
                        NSPredicate(format: "isRemoved == false"),
                        Note.notMarkedForLocalDeletionPredicate,
                        Note.notMarkedForRemoteDeletionPredicate
                    ])
                let allCount = try context.count(for: noteRequest)
                noteRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "isLocked == true"),
                    NSPredicate(format: "isRemoved == false"),
                    Note.notMarkedForLocalDeletionPredicate,
                    Note.notMarkedForRemoteDeletionPredicate
                    ])
                let lockedCount = try context.count(for: noteRequest)
                noteRequest.predicate = NSPredicate(format: "isRemoved == true")
                noteRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "isLocked == false"),
                    NSPredicate(format: "isRemoved == true"),
                    Note.notMarkedForLocalDeletionPredicate,
                    Note.notMarkedForRemoteDeletionPredicate
                    ])
                let removedCount = try context.count(for: noteRequest)

                allFolderView.titleLabel.text = "모든 메모"
                lockedFolderView.titleLabel.text = "잠긴 메모"
                removedFolderView.titleLabel.text = "휴지통"

                allFolderView.countLabel.text = String(allCount)
                lockedFolderView.countLabel.text = String(lockedCount)
                removedFolderView.countLabel.text = String(removedCount)

                allFolderView.systemFolderStateRepresentation = .all
                lockedFolderView.systemFolderStateRepresentation = .locked
                removedFolderView.systemFolderStateRepresentation = .removed

                allFolderView.delegate = delegate
                lockedFolderView.delegate = delegate
                removedFolderView.delegate = delegate

            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
