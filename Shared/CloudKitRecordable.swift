//
//  CloudKitRecordable.swift
//  Piano
//
//  Created by hoemoon on 08/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import CloudKit
import Result

protocol CloudKitRecordable {
    var isMine: Bool { get }
    var cloudKitRecord: CKRecord? { get }
}

extension Note: CloudKitRecordable {
    var cloudKitRecord: CKRecord? {
        guard let ckRecord = self.recordArchive?.ckRecorded else { return nil }
        if let content = content {
            ckRecord[NoteField.content] = content as CKRecordValue
        }
        if let location = location as? CLLocation {
            ckRecord[NoteField.location] = location
        }
        if !isShared {
            if let tags = tags {
                ckRecord[NoteField.tags] = tags as CKRecordValue
            }
            ckRecord[NoteField.isRemoved] = (isRemoved ? 1 : 0) as CKRecordValue
            //  ckRecord[Fields.isLocked] = (isLocked ? 1 : 0) as CKRecordValue
            ckRecord[NoteField.isPinned] = isPinned as CKRecordValue
        }
        ckRecord[NoteField.createdAtLocally] = createdAt
        ckRecord[NoteField.modifiedAtLocally] = modifiedAt
        return ckRecord
    }
}

extension ImageAttachment: CloudKitRecordable {
    var cloudKitRecord: CKRecord? {
        guard let ckRecord = self.recordArchive?.ckRecorded else { return nil }
        if let imageData = imageData {
            switch imageData.temporaryURL {
            case .success(let url):
                ckRecord[ImageField.imageData] = CKAsset(fileURL: url)
            case .failure(let error):
                print(error)
            }
        }
        ckRecord[ImageField.createdAtLocally] = createdAt
        ckRecord[ImageField.modifiedAtLocally] = modifiedAt

        return ckRecord
    }
}

enum SaveDataError: Error {
    case UnableToWrite
}

extension NSData {
    var temporaryURL: Result<URL, SaveDataError> {
        return Result(catching: {
            let filename = "\(ProcessInfo.processInfo.globallyUniqueString).png"
            var url = URL(fileURLWithPath: NSTemporaryDirectory())
            url.appendPathComponent(filename)
            try self.write(to: url, options: .atomicWrite)
            return url
        })
    }
}
