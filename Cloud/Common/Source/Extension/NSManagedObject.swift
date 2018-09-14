//
//  NSManagedObjectContext.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 4..
//

import CoreData

public extension NSManagedObject {
    
    /**
     Object와 연동된, 또는 새로 생성한 CKRecord.
     - Parameter remake: 새롭게 record를 생성해야 할때.
     */
    public func record(_ remake: Bool = false) -> CKRecord? {
        guard !remake else {return createRecord()}
        if let metaData = value(forKey: KEY_RECORD_DATA) as? Data {
            let coder = NSKeyedUnarchiver(forReadingWith: metaData)
            coder.requiresSecureCoding = true
            let record = CKRecord(coder: coder)
            coder.finishDecoding()
            return record
        } else {
            return createRecord()
        }
    }
    
    private func createRecord() -> CKRecord? {
        guard let entityName = entity.name else {return nil}
        let recordID = CKRecord.ID(recordName: UUID().uuidString, zoneID: ZONE_ID)
        let record = CKRecord(recordType: entityName, recordID: recordID)
        setValue(record.metadata, forKey: KEY_RECORD_DATA)
        setValue(record.recordID.recordName, forKey: KEY_RECORD_NAME)
        return record
    }
    
}

