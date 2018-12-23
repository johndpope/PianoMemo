//
//  RemoteDeletable.swift
//  Piano
//
//  Created by hoemoon on 23/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData

private let MarkedForRemoteDeletionKey = "markedForRemoteDeletion"


protocol RemoteDeletable: class {
    var changedForRemoteDeletion: Bool { get }
    var markedForRemoteDeletion: Bool { get set }
    func markForRemoteDeletion()
}

extension RemoteDeletable {
    static var notMarkedForRemoteDeletionPredicate: NSPredicate {
        return NSPredicate(format: "%K == false", MarkedForRemoteDeletionKey)
    }

    static var markedForRemoteDeletionPredicate: NSPredicate {
        return NSCompoundPredicate(notPredicateWithSubpredicate: notMarkedForRemoteDeletionPredicate)
    }

    func markForRemoteDeletion() {
        markedForRemoteDeletion = true
    }
}

extension RemoteDeletable where Self: NSManagedObject {
    var changedForRemoteDeletion: Bool {
        return changedValue(forKey: MarkedForRemoteDeletionKey) as? Bool == true
    }
}


