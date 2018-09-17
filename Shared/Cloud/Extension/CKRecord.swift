//
//  CKRecord.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 9..
//

import CloudKit
import CoreData

public extension CKRecord {
    
    /// CKRecord의 metadata.
    public var metadata: Data {
        let data = NSMutableData()
        let coder = NSKeyedArchiver(forWritingWith: data)
        coder.requiresSecureCoding = true
        encodeSystemFields(with: coder)
        coder.finishEncoding()
        return Data(referencing: data)
    }
    
    internal func syncMetaData(using context: NSManagedObjectContext) {
        guard recordType != SHARE_RECORD_TYPE else {return}
        context.name = FETCH_CONTEXT
        context.performAndWait {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: self.recordType)
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "\(KEY_RECORD_NAME) == %@", self.recordID.recordName)
            if let object = try? context.fetch(request).first as? NSManagedObject, let strongObject = object {
                strongObject.setValue(self.metadata, forKey: KEY_RECORD_DATA)
            }
            if context.hasChanges {
                try? context.save()
                context.name = nil
            }
        }
    }
    
}

