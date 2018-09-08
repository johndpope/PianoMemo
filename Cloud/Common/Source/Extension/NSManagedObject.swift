//
//  NSManagedObjectContext.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 4..
//

import CoreData

internal extension NSManagedObject {
    
    /// "recordData" 또는 새로 생성한 CKRecord.
    internal func makeRecordIfNeeded() -> CKRecord? {
        if let metaData = value(forKey: KEY_RECORD_DATA) as? Data {
            let coder = NSKeyedUnarchiver(forReadingWith: metaData)
            coder.requiresSecureCoding = true
            let record = CKRecord(coder: coder)
            coder.finishDecoding()
            return record
        } else {
            guard let entityName = entity.name else {return nil}
            let record = CKRecord(recordType: entityName, zoneID: ZONE_ID)
            setValue(record.metadata, forKey: KEY_RECORD_DATA)
            setValue(record.recordID.recordName, forKey: KEY_RECORD_NAME)
            return record
        }
    }
    
}
