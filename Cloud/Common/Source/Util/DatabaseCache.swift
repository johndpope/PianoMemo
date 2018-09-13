//
//  DatabaseCache.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 4..
//

internal class DatabaseCache {
    
    internal let database: CKDatabase
    
    internal var recordsToSave = [CKRecord]()
    internal var recordIDsToDelete = [CKRecord.ID]()
    
    internal init(database: CKDatabase) {
        self.database = database
    }
    
}
