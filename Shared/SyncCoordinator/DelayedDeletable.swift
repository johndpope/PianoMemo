//
//  DelayedDeletable.swift
//  Piano
//
//  Created by hoemoon on 23/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData

/// 런타임에 곧바로 객체를 삭제하지 않고, 백그라운드 진입시에 batch- api를 이용해
/// 데이터베이스에서 객체를 삭제하게 됩니다.
protocol DelayedDeletable: class {
    var markedForDeletionDate: Date? { get set }
    func markForLocalDeletion()
}

extension DelayedDeletable {
    static var notMarkedForLocalDeletionPredicate: NSPredicate {
        return NSPredicate(format: "%K == NULL", NoteKey.markedForDeletionDate.rawValue)
    }
}

extension DelayedDeletable where Self: NSManagedObject {
    /// 코어데이터 객체를 삭제하는 것을 예약합니다.
    /// `markedForDeletionDate`에 현재 시간을 기록합니다.
    /// 앱이 백그라운드에 진입하게 되면, 그때의 시간을 기준으로 2분이 경과한 객체들은 삭제 됩니다.
    func markForLocalDeletion() {
        guard isFault || markedForDeletionDate == nil else { return }
        markedForDeletionDate = Date()
    }
}

private let DeletionAgeBeforePermanentlyDeletingObjects = TimeInterval(2 * 60)

extension NSManagedObjectContext {
    /// 외부에서 배치삭제를 요청하는 메서드입니다.
    func batchDeleteObjectsMarkedForLocalDeletion() {
        Note.batchDeleteObjectsMarkedForLocalDeletionInContext(self)
        ImageAttachment.batchDeleteObjectsMarkedForLocalDeletionInContext(self)
        Note.batchDeleteOldTrash(self)
    }
}

extension DelayedDeletable where Self: NSManagedObject, Self: Managed {
    /// 삭제 예약한 코어 데이터 중 최소 2분이 경과한 것들을 배치로 삭제합니다.
    /// 배치 삭제후 컨텍스트에 변경사항을 병합하는 것을 포함합니다.
    fileprivate static func batchDeleteObjectsMarkedForLocalDeletionInContext(_ managedObjectContext: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName)
        let cutoff = Date(timeIntervalSinceNow: -DeletionAgeBeforePermanentlyDeletingObjects)
        fetchRequest.predicate = NSPredicate(format: "%K < %@", "markedForDeletionDate", cutoff as NSDate)
        let batchRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchRequest.resultType = .resultTypeObjectIDs
        managedObjectContext.performAndWait {
            do {
                let result = try managedObjectContext.execute(batchRequest) as? NSBatchDeleteResult
                let objectIDArray = result?.result as! [NSManagedObjectID]
                let changes = [NSDeletedObjectsKey: objectIDArray]
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: changes,
                    into: [managedObjectContext]
                )
            } catch {
                print(error)
            }
        }
    }

    /// 30일 이상 휴지통에 있는 노트를 배치 삭제합니다.
    /// 배치 삭제후 컨텍스트에 변경사항을 병합하는 것을 포함합니다.
    fileprivate static func batchDeleteOldTrash(_ managedObjectContext: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName)
        fetchRequest.predicate = NSPredicate(format: "isRemoved == true AND modifiedAt < %@", NSDate(timeIntervalSinceNow: -3600 * 24 * 30))
        let batchRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchRequest.resultType = .resultTypeObjectIDs
        managedObjectContext.performAndWait {
            do {
                let result = try managedObjectContext.execute(batchRequest) as? NSBatchDeleteResult
                let objectIDArray = result?.result as! [NSManagedObjectID]
                let changes = [NSDeletedObjectsKey: objectIDArray]
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: changes,
                    into: [managedObjectContext]
                )
            } catch {
                print(error)
            }
        }
    }
}
