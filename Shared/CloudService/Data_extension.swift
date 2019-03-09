//
//  Data_extesion.swift
//  Piano
//
//  Created by 박주혁 on 07/03/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation
import CloudKit

extension Data {
    var cloudRecord: CKRecord? {
        do {
            let coder = try NSKeyedUnarchiver(forReadingFrom: self)
            let record = CKRecord(coder: coder)
            return record
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}
