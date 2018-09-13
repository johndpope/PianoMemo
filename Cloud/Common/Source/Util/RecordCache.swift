//
//  RecordCache.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 4..
//

import CoreData

internal class RecordCache {
    
    internal let database: CKDatabase
    internal let managedUnit: ManagedUnit
    
    internal init(_ database: CKDatabase, _ managedUnit: ManagedUnit) {
        self.database = database
        self.managedUnit = managedUnit
    }
    
}

