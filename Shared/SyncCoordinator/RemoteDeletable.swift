//
//  RemotePurgeReservable.swift
//  Piano
//
//  Created by hoemoon on 23/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData

/// 원격 저장소에서 삭제하는 것을 예약하는 기능을 정의하는 프로토콜
protocol RemoteDeletable: class {
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

    /// 원격 저장소에서의 삭제를 예약합니다.
    func markForRemoteDeletion() {
        markedForRemoteDeletion = true
    }
}
