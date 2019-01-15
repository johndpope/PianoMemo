//
//  CKRecord.swift
//  Piano
//
//  Created by hoemoon on 10/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit

typealias RecordWrapper = (Bool, CKRecord)

extension CKRecord {
    var archived: NSData {
        let data = NSMutableData()
        let coder = NSKeyedArchiver(forWritingWith: data)
        coder.requiresSecureCoding = true
        self.encodeSystemFields(with: coder)
        coder.finishEncoding()
        return data
    }

    // TODO:
    var isShared: Bool {
        return share != nil
    }

    var modifiedAtLocally: NSDate? {
        return self[NoteField.modifiedAtLocally] as? NSDate
    }
}

extension Note {
    var remoteID: CKRecord.ID? {
        return recordID as? CKRecord.ID
    }
}

extension ImageAttachment {
    var remoteID: CKRecord.ID? {
        return recordID as? CKRecord.ID
    }
}
