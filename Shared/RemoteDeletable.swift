//
//  RemotePurgeReservable.swift
//  Piano
//
//  Created by hoemoon on 23/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData

protocol RemoteDeletable: class {
//    var changedForRemoteDeletion: Bool { get }
    var markedForRemoteDeletion: Bool { get set }
    func markForRemoteDeletion()
}

extension RemoteDeletable {
    static var notMarkedForRemoteDeletionPredicate: NSPredicate {
        return NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "%K == false", NoteKey.markedForRemoteDeletion.rawValue),
            NSPredicate(format: "%K == NULL", NoteKey.markedForRemoteDeletion.rawValue)])
    }

    static var markedForRemoteDeletionPredicate: NSPredicate {
        return NSPredicate(format: "%K == true", NoteKey.markedForRemoteDeletion.rawValue)
    }

    func markForRemoteDeletion() {
        markedForRemoteDeletion = true
    }
}
