//
//  CloudKitRecordable.swift
//  Piano
//
//  Created by hoemoon on 08/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import CloudKit
import CoreData
import Result

enum CloudKitRecodableKeys: String {
    case recordID
}

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
    var localExclusiveKeys: [String] {
        return ["createdBy", "isMine", "isShared", "markedForDeletionDate", "markedForRemoteDeletion", "markedForUploadReserved", "modifiedBy", "recordArchive", "recordID"]
    }
}

extension ImageAttachment: CloudKitRecordable {
    var localExclusiveKeys: [String] {
        return ["isMine", "markedForDeletionDate", "markedForRemoteDeletion", "markedForUploadReserved", "recordArchive", "recordID"]
    }
}

extension Folder: CloudKitRecordable {
    var localExclusiveKeys: [String] {
        return ["isMine", "markedForDeletionDate", "markedForRemoteDeletion", "markedForUploadReserved", "recordArchive", "recordID"]
    }
}

extension CloudKitRecordable where Self: NSManagedObject {
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
