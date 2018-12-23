//
//  UploadReservable.swift
//  Piano
//
//  Created by hoemoon on 23/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData

protocol UploadReservable: class {
    var markedForUploadReserved: Bool { get set }
    func markUploadReserved()
    func resolveUploadReserved()
}

extension UploadReservable where Self: NSManagedObject {
    func markUploadReserved() {
        markedForUploadReserved = true
    }

    func resolveUploadReserved() {
        if markedForUploadReserved {
            markedForUploadReserved = false
        }
    }
}
