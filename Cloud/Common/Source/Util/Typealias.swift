//
//  Typealias.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 10..
//

import CoreData

/// Cloud & CoreData container.
public typealias Container = (cloud: CKContainer, coreData: NSPersistentContainer)
/// CKRecord & NSManagedObject.
public typealias ManagedUnit = (record: CKRecord?, object: NSManagedObject?)
/// ancestorRecord & serverRecord & clientRecord
public typealias ConflictRecord = (ancestor: CKRecord?, server: CKRecord?, client: CKRecord?)
