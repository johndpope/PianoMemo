//
//  Data.swift
//  Piano
//
//  Created by hoemoon on 14/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit

extension Data {
    var ckRecorded: CKRecord? {
        let coder = NSKeyedUnarchiver(forReadingWith: self)
        coder.requiresSecureCoding = true
        let record = CKRecord(coder: coder)
        coder.finishDecoding()
        return record
    }
}
