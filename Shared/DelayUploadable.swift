//
//  DelayUploadable.swift
//  Piano
//
//  Created by hoemoon on 23/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData

protocol ReserveUploadable: class {
    var markedForUploadReserved: Bool { get set }
    func markUploadReserved()
    func unmarkUploadReserved()
}

extension ReserveUploadable where Self: NSManagedObject {
    func markUploadReserved() {
        markedForUploadReserved = true
    }

    func unmarkUploadReserved() {
        markedForUploadReserved = false
    }
}
