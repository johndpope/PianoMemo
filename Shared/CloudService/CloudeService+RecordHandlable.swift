//
//  RecordHandlable.swift
//  Piano
//
//  Created by hoemoon on 31/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CloudKit
import CoreData

/// 원격 저장소에서 받은 레코드로 로컬 데이터베이스를 갱신하는 역할을 표현하는 프로토콜
protocol RecordHandlable: class {
    var backgroundContext: NSManagedObjectContext! { get }
    func createOrUpdate(record: CKRecord, isMine: Bool, completion: (Bool) -> Void)
    func remove(recordID: CKRecord.ID, completion: (Bool) -> Void)
}

extension RecordHandlable {
    /// 원격 저장소에서 받은 레코드를 이용해 로컬데이터베이스에 새로운 객체를 생성하거나
    /// 로컬데이터베이스에 있는 기존 객체를 갱신하는 메서드
    /// 1. 레코드 타입 정보를 이용해서 모델 정보를 가져온다.
    /// 2. 모델 정보를 이용해 NSFetchRequest를 생성한다.
    /// 3. 객체를 찾으면 갱신하고, 없으면 생성한다.
    ///
    /// - Parameters:
    ///   - record: 원격 저장소에서 가져온 레코드
    ///   - isMine: private 또는 share 데이터베이스에 왔는지를 표시
    ///   - completion: completion handler
    func createOrUpdate(record: CKRecord, isMine: Bool, completion: (Bool) -> Void) {
        // 원격 저장소에는 Image로 레코드타입이 만들어져 있지만,
        // 로컬에서는 이미 Image가 쓰이고 있기 때문에 ImageAttachment으로 모델을 표현하고 있다.
        // 이 경우 아래의 코드로 보정하고 있다.
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

    /// 원격 저장소에서 삭제된 레코드 식별자를 이용해 로컬 저장소에서
    /// 위의 메서드와 같은 방식으로 레코드를 찾아서 삭제될 노트로 예약한다.
    ///
    /// - Parameters:
    ///   - recordID: 삭제된 레코드 식별자
    ///   - completion: completion handler
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
    /// 레코드를 이용해 코어데이터 객체를 업데이트하는 메서드
    /// json 객체를 swift 객체로 serialize하는 것과 똑같은 역할을 수행합니다.
    ///
    /// - Parameters:
    ///   - origin: 기존 코어데이터 객체
    ///   - record: 원격 저장소 레코드
    ///   - isMine: private 또는 share 데이터베이스에 왔는지를 표시
    private func performUpdate(origin: NSManagedObject, with record: CKRecord, isMine: Bool) {
        let attributes = origin.entity.attributesByName
        // transformable 필드가 있다면 그 키를 저장합니다.
        var transformableAttributeKeys = Set<String>()
        for (key, attributeDescription) in attributes where attributeDescription.attributeType == NSAttributeType.transformableAttributeType {
            transformableAttributeKeys.insert(key)
        }
        // 로컬에만 존재하는 값은 별도로 처리합니다.
        origin.setValue(isMine, forKey: "isMine")
        origin.setValue(record.archived, forKey: "recordArchive")
        origin.setValue(record.recordID, forKey: "recordID")
        // 레코드를 이용해 해당 코어데이터 객체를 dictionary 형태로 가져와서 업데이트 합니다.
        if var dict = record.allAttributeValuesAsManagedObjectAttributeValues(usingContext: backgroundContext) {
            dict = replaceAssets(in: dict)
            dict = transformAttributes(in: dict, keys: transformableAttributeKeys)
            dict = replaceDateKeys(in: dict)
            origin.setValuesForKeys(dict)
        }
        // 레코드가 관계를 가진 경우, 해당 코어데이터 객체를 찾아서 연결합니다.
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

    /// transformable 타입 필드를 갱신 합니다
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

    /// ckAsset으로 바이너리 데이터를 갱신 합니다.
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
    /// 현재 앱에만 적용되는 케이스입니다.
    /// 로컬에서의 생성 시점과 변경 시점을 -Locally라는 이름으로 클라우드에 저장하고 있지만,
    /// 로컬 저장소에는 -Locally 없이 저장하고 있어서
    /// 발생하는 차이를 보완하는 메서드 입니다.
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
    /// 레코드에서 키들을 추출하는 메서드입니다.
    /// 필요없는 키를 제거한 후 반환합니다.
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

    /// 코어데이터 모델 정보를 이용해서 레코드를 [String: AnyObject]? 형태로 만들어 반환합니다.
    fileprivate func allAttributeValuesAsManagedObjectAttributeValues(usingContext context: NSManagedObjectContext) -> [String: AnyObject]? {
        let recordType = self.recordType == "Image" ? "ImageAttachment" : self.recordType
        if let entity = context.persistentStoreCoordinator?.managedObjectModel.entitiesByName[recordType] {
            return self.dictionaryWithValues(forKeys: self.allAttributeKeys(usingAttributesByNameFromEntity: entity.attributesByName)) as [String: AnyObject]?
        } else {
            return nil
        }
    }
}
