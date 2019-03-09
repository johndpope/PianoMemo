//
//  CKRecordable.swift
//  Piano
//
//  Created by 박주혁 on 07/03/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

protocol CKRecordable {
    //core data(stored) property
    var recordName: String? { get set }
    var recordMetaData: Data? { get set }
    
    //computed property
    var recordID: CKRecord.ID? { get }
    var record: CKRecord? { get }
    var localOnlyAttributes: [String] { get }
}

extension CKRecordable where Self: NSManagedObject {
    var recordID: CKRecord.ID? {
        guard let data = recordMetaData else { return nil}
        return data.cloudRecord?.recordID
    }
    
    var record: CKRecord? {
        guard let data = self.recordMetaData,
            let record = data.cloudRecord else { return nil }
        
        let attributes = self.entity.attributesByName.filter{ !localOnlyAttributes.contains($0.key) }
        attributes.forEach { attribute in
            let fieldKey = attribute.key
            let rawValue = self.value(forKey: fieldKey)
            
            if rawValue == nil {
                record.setNilValueForKey(fieldKey)
                return
            }
            
            switch attribute.value.attributeType {
            case .undefinedAttributeType:
                break
            case .integer16AttributeType, .integer32AttributeType, .integer64AttributeType, .decimalAttributeType, .doubleAttributeType, .floatAttributeType, .booleanAttributeType:
                let value = (rawValue as! NSNumber) as CKRecordValue
                record.setObject(value, forKey: fieldKey)
                
            case .stringAttributeType:
                let value = (rawValue as! NSString) as CKRecordValue
                record.setObject(value, forKey: fieldKey)
                
            case .dateAttributeType:
                let value = (rawValue as! NSDate) as CKRecordValue
                record.setObject(value, forKey: fieldKey)
                
            case .binaryDataAttributeType:
                let value = (rawValue as! NSData) as CKRecordValue
                record.setObject(value, forKey: fieldKey)
                
            case .UUIDAttributeType:
                break
                
            case .URIAttributeType:
                break
                
            case .transformableAttributeType:
                break
                
            case .objectIDAttributeType:
                break
            }
        }
        
        return record
    }
    
    var localOnlyAttributes: [String] {
        return ["recordName", "recordMetaData"]
    }
}
