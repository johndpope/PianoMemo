//
//  RecordHandlable.swift
//  Piano
//
//  Created by hoemoon on 31/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CloudKit
import CoreData
import Kuery

protocol RecordHandlable: class {
    var backgroundContext: NSManagedObjectContext! { get }
    func createOrUpdate(record: CKRecord, isMine: Bool, completion: (Bool) -> Void)
    func remove(recordID: CKRecord.ID, completion: (Bool) -> Void)
}

extension RecordHandlable {
    func createOrUpdate(record: CKRecord, isMine: Bool, completion: (Bool) -> Void) {
        let recordType = record.recordType == "Image" ? "ImageAttachment" : record.recordType
        backgroundContext.performAndWait {
            do {
                if let entity = backgroundContext.persistentStoreCoordinator?.managedObjectModel.entitiesByName[recordType],
                    let entityName = entity.name {
                    let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                    request.predicate = NSPredicate(format: "recordID == %@", record.recordID)
                    request.returnsObjectsAsFaults = false
                    request.fetchLimit = 1
                    let results = try backgroundContext.fetch(request)
                    if !results.isEmpty {
                        if let object = results.first as? NSManagedObject {
                            performUpdate(origin: object, with: record, isMine: isMine)
                        }
                    } else {
                        let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: backgroundContext)
                        performUpdate(origin: object, with: record, isMine: isMine)
                    }
                    backgroundContext.saveOrRollback()
                    completion(true)
                }
            } catch {
                completion(false)
            }
        }
    }

    func remove(recordID: CKRecord.ID, completion: (Bool) -> Void) {
        backgroundContext.performAndWait {
            do {
                if let entitiesByName = backgroundContext.persistentStoreCoordinator?.managedObjectModel.entitiesByName {
                    for key in entitiesByName.keys {
                        if let entityName = entitiesByName[key]?.name {
                            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                            request.predicate = NSPredicate(format: "recordID == %@", recordID)
                            request.fetchLimit = 1

                            let result = try backgroundContext.fetch(request)
                            if let deletable = result.first as? DelayedDeletable {
                                deletable.markForLocalDeletion()
                            }
                        }
                    }
                    backgroundContext.saveOrRollback()
                    completion(true)
                }
            } catch {
                completion(false)
            }
        }
    }
}

extension RecordHandlable {
    private func performUpdate(origin: NSManagedObject, with record: CKRecord, isMine: Bool) {
        let attributes = origin.entity.attributesByName
        var transformableAttributeKeys = Set<String>()
        for (key, attributeDescription) in attributes where attributeDescription.attributeType == NSAttributeType.transformableAttributeType {
            transformableAttributeKeys.insert(key)
        }
        origin.setValue(isMine, forKey: "isMine")
        origin.setValue(record.archived, forKey: "recordArchive")
        if var dict = record.allAttributeValuesAsManagedObjectAttributeValues(usingContext: backgroundContext) {
            dict = replaceAssets(in: dict)
            dict = transformAttributes(in: dict, keys: transformableAttributeKeys)
            dict = replaceDateKeys(in: dict)
            origin.setValuesForKeys(dict)
        }

        let relationships = record.allKeys().filter { origin.entity.relationshipsByName[$0] != nil }
        for relationship in relationships {
            if let ckReference = record[relationship] as? CKRecord.Reference,
                let destinationEntityName = origin.entity.relationshipsByName[relationship]?.destinationEntity?.name {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: destinationEntityName)
                request.predicate = NSPredicate(format: "recordID == %@", ckReference.recordID)
                request.fetchLimit = 1
                do {
                    let result = try backgroundContext.fetch(request)
                    if !result.isEmpty {
                        if let first = result.first as? NSManagedObject {
                            origin.setValue(first, forKey: relationship)
                        }
                    }
                } catch {
                    print(error)
                }
            }
        }
    }

    private func transformAttributes(in dictionary: [String: AnyObject], keys: Set<String>) -> [String: AnyObject] {
        var returnDict = [String: AnyObject]()
        for (key, value) in dictionary {
            if keys.contains(key) {
                if let data = dictionary[key] as? Data {
                    let unarchived = NSKeyedUnarchiver.unarchiveObject(with: data) as AnyObject
                    returnDict[key] = unarchived
                }
            } else {
                returnDict[key] = value
            }
        }
        return returnDict
    }

    private func replaceAssets(in dictionary: [String: AnyObject]) -> [String: AnyObject] {
        var returnDict = [String: AnyObject]()
        for (key, value) in dictionary {
            if let val = value as? CKAsset {
                if let assetData = NSData(contentsOfFile: val.fileURL.path) {
                    returnDict[key] = assetData
                }
            } else {
                returnDict[key] = value
            }
        }
        return returnDict
    }

    private func replaceDateKeys(in dictionary: [String: AnyObject]) -> [String: AnyObject] {
        var returnDict = [String: AnyObject]()
        for (key, value) in dictionary {
            if key == "createdAtLocally" {
                returnDict["createdAt"] = value
            } else if key == "modifiedAtLocally" {
                returnDict["modifiedAt"] = value
            } else {
                returnDict[key] = value
            }
        }
        return returnDict
    }
}

extension CloudService: RecordHandlable {}

extension CKRecord {
    func allAttributeKeys(usingAttributesByNameFromEntity attributesByName: [String: NSAttributeDescription]) -> [String] {
        var filtered = allKeys().filter { attributesByName[$0] != nil }
        filtered.append(contentsOf: ["createdAtLocally", "modifiedAtLocally"])
        if let index = filtered.firstIndex(of: "createdAt") {
            filtered.remove(at: index)
        }
        if let index = filtered.firstIndex(of: "modifiedAt") {
            filtered.remove(at: index)
        }
        return filtered
    }

    fileprivate func allAttributeValuesAsManagedObjectAttributeValues(usingContext context: NSManagedObjectContext) -> [String: AnyObject]? {
        if let entity = context.persistentStoreCoordinator?.managedObjectModel.entitiesByName[self.recordType] {
            return self.dictionaryWithValues(forKeys: self.allAttributeKeys(usingAttributesByNameFromEntity: entity.attributesByName)) as [String: AnyObject]?
        } else {
            return nil
        }
    }
}
