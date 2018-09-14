//
//  Uploadable.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 4..
//

import CoreData

internal protocol Uploadable: class {
    var container: Container {get set}
    var recordsToSave: [RecordCache] {get set}
    var recordIDsToDelete: [RecordCache] {get set}
}

internal extension Uploadable where Self: ErrorHandleable {
    
    internal func cache(_ insertedObjects: Set<NSManagedObject>, _ updatedObjects: Set<NSManagedObject>, _ deletedObjects: Set<NSManagedObject>, _ remakeIfNeeded: Bool = false) {
        for insertedObject in insertedObjects {
            guard let record = insertedObject.record(remakeIfNeeded) else {continue}
            let managedUnit = ManagedUnit(record: record, object: insertedObject)
            recordsToSave.append(RecordCache(database(for: record.recordID), managedUnit))
        }
        for updatedObject in updatedObjects {
            guard let record = updatedObject.record(remakeIfNeeded) else {continue}
            let managedUnit = ManagedUnit(record: record, object: updatedObject)
            recordsToSave.append(RecordCache(database(for: record.recordID), managedUnit))
        }
        for deletedObject in deletedObjects {
            guard let record = deletedObject.record(remakeIfNeeded) else {continue}
            let managedUnit = ManagedUnit(record: record, object: nil)
            recordIDsToDelete.append(RecordCache(database(for: record.recordID), managedUnit))
        }
    }
    
    internal func upload(using context: NSManagedObjectContext) {
        let converter = Converter()
        for (idx, cache) in recordsToSave.enumerated() {
            recordsToSave[idx] = RecordCache(cache.database, converter.object(toRecord: cache.managedUnit))
        }
        var datasource = [DatabaseCache]()
        for recordCache in recordsToSave {
            guard let record = recordCache.managedUnit.record else {continue}
            if let databaseCache = datasource.first(where: {$0.database == recordCache.database}) {
                databaseCache.recordsToSave.append(record)
            } else {
                let databaseCache = DatabaseCache(database: recordCache.database)
                databaseCache.recordsToSave.append(record)
                datasource.append(databaseCache)
            }
        }
        for recordCache in recordIDsToDelete {
            guard let record = recordCache.managedUnit.record else {continue}
            if let databaseCache = datasource.first(where: {$0.database == recordCache.database}) {
                databaseCache.recordIDsToDelete.append(record.recordID)
            } else {
                let databaseCache = DatabaseCache(database: recordCache.database)
                databaseCache.recordIDsToDelete.append(record.recordID)
                datasource.append(databaseCache)
            }
        }
        recordsToSave.removeAll()
        recordIDsToDelete.removeAll()
        datasource.forEach {operate(with: $0, using: context)}
    }
    
    private func database(for recordID: CKRecord.ID) -> CKDatabase {
        if recordID.zoneID.ownerName == CKCurrentUserDefaultName {
            return container.cloud.privateCloudDatabase
        } else {
            return container.cloud.sharedCloudDatabase
        }
    }
    
    private func operate(with datasource: DatabaseCache, using context: NSManagedObjectContext) {
        let operation = CKModifyRecordsOperation(recordsToSave: datasource.recordsToSave, recordIDsToDelete: datasource.recordIDsToDelete)
        operation.perRecordCompletionBlock = { record, error in
            print("upload :", record, error ?? "no error")
            if let error = error {
                self.errorBlock?(error)
            } else {
                self.removeAsset(using: record)
                record.syncMetaData(using: context)
            }
        }
        operation.modifyRecordsCompletionBlock = {self.errorBlock?($2)}
        datasource.database.add(operation)
    }
    
    private func removeAsset(using record: CKRecord) {
        for key in record.allKeys() {
            guard let asset = record.value(forKey: key) as? CKAsset else {continue}
            try? FileManager.default.removeItem(at: asset.fileURL)
        }
    }
    
}

