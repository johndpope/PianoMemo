//
//  CKRecord.swift
//  Piano
//
//  Created by hoemoon on 10/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit

extension CKRecord {
    var archived: Data {
        let data = NSMutableData()
        let coder = NSKeyedArchiver(forWritingWith: data)
        coder.requiresSecureCoding = true
        self.encodeSystemFields(with: coder)
        coder.finishEncoding()
        return Data(referencing: data)
    }

    var isShared: Bool {
        return share != nil
    }

}
