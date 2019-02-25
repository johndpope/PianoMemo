//
//  CloudKitRecordable.swift
//  Piano
//
//  Created by hoemoon on 08/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import CloudKit
import CoreData

/// 클라우드킷 레코드로 표현 가능한 객체를 정의하는 프로토콜
protocol CloudKitRecordable: class {
    var isMine: Bool { get }
    var recordArchive: Data? { get set }
    var cloudKitRecord: CKRecord? { get }
    var recordID: NSObject? { get set }
    var modifiedAt: Date? { get }

    var localExclusiveKeys: [String] { get }
}

extension CloudKitRecordable {
    var remoteID: CKRecord.ID? {
        return recordID as? CKRecord.ID
    }
}

extension Note: CloudKitRecordable {
    /// 로컬에만 존재하는 키를 표현
    var localExclusiveKeys: [String] {
        return ["createdBy", "isMine", "isShared", "markedForDeletionDate", "markedForRemoteDeletion", "markedForUploadReserved", "modifiedBy", "recordArchive", "recordID"]
    }
}

extension ImageAttachment: CloudKitRecordable {
    /// 로컬에만 존재하는 키를 표현
    var localExclusiveKeys: [String] {
        return ["isMine", "markedForDeletionDate", "markedForRemoteDeletion", "markedForUploadReserved", "recordArchive", "recordID"]
    }
}

extension Folder: CloudKitRecordable {
    /// 로컬에만 존재하는 키를 표현
    var localExclusiveKeys: [String] {
        return ["isMine", "markedForDeletionDate", "markedForRemoteDeletion", "markedForUploadReserved", "recordArchive", "recordID"]
    }
}

extension CloudKitRecordable where Self: NSManagedObject {
    /// 코어데이터 객체를 클라우드킷 레코드로 변환해주는 computed property
    /// 키 각각의 타입에 따라서 다른 serialize 과정을 거칩니다.
    var cloudKitRecord: CKRecord? {
        guard let ckRecord = self.recordArchive?.ckRecorded else { return nil }
        let attrkeys = entity.attributesByName.keys.filter { !localExclusiveKeys.contains($0) }
        for key in attrkeys {
            if let attributeDescription = entity.attributesByName[key] {
                let attrName = attributeDescription.name
                if self.value(forKey: attrName) != nil {
                    switch attributeDescription.attributeType {
                    case .stringAttributeType:
                        ckRecord.setObject(self.value(forKey: attrName) as! String as CKRecordValue, forKey: attrName)
                    case .dateAttributeType:
                        ckRecord.setObject(self.value(forKey: attrName) as! Date as CKRecordValue, forKey: "\(attrName)Locally")
                    case .booleanAttributeType, .decimalAttributeType, .doubleAttributeType, .floatAttributeType, .integer16AttributeType, .integer32AttributeType, .integer64AttributeType:
                        ckRecord.setObject(self.value(forKey: attrName) as! NSNumber, forKey: attrName)
                    case .binaryDataAttributeType:
                        if attributeDescription.allowsExternalBinaryDataStorage,
                            let data = self.value(forKey: attrName) as? Data,
                            let url = data.temporaryURL {
                            let asset = CKAsset(fileURL: url)
                            ckRecord.setObject(asset, forKey: attrName)
                        } else {
                            ckRecord.setObject(self.value(forKey: attrName) as! Data as CKRecordValue, forKey: attrName)
                        }
                    case .transformableAttributeType:
                        if attributeDescription.valueTransformerName == nil {
                            if let value = self.value(forKey: attrName) as? NSCoding {
                                let data = NSKeyedArchiver.archivedData(withRootObject: value)
                                if attributeDescription.allowsExternalBinaryDataStorage, let url = data.temporaryURL {
                                    ckRecord.setObject(CKAsset(fileURL: url), forKey: attrName)
                                } else {
                                    ckRecord.setObject(data as CKRecordValue?, forKey: attrName)
                                }
                            }
                        }
                    default:
                        break
                    }
                } else {
                    ckRecord.setObject(nil, forKey: attrName)
                }
            }
        }
        // 관계를 가진 객체가 있는 경우
        let relationshipKeys = self.entity.relationshipsByName.keys
        for key in relationshipKeys {
            var ckReference: CKRecord.Reference?
            if let description = self.entity.relationshipsByName[key] {
                let attrName = description.name
                if let recordable = self.value(forKey: attrName) as? CloudKitRecordable,
                    let record = recordable.recordArchive?.ckRecorded {
                    ckReference = CKRecord.Reference(record: record, action: .none)
                }
            }
            ckRecord.setObject(ckReference, forKey: key)
        }
        return ckRecord
    }
}

extension Data {
    /// 임시로 바이너리 데이터를 디스크에 저장한 후
    /// 업로드시 사용할 url을 제공하는 computed property
    var temporaryURL: URL? {
        do {
            let filename = "\(ProcessInfo.processInfo.globallyUniqueString)._file.bin"
            var url = URL(fileURLWithPath: NSTemporaryDirectory())
            url.appendPathComponent(filename)
            try self.write(to: url, options: .atomicWrite)
            return url
        } catch {
            return nil
        }
    }
}
