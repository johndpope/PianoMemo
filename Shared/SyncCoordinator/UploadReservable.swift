//
//  UploadReservable.swift
//  Piano
//
//  Created by hoemoon on 23/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData

/// 원격 저장소 업로드를 예약하는 기능을 정의하는 프로토콜
protocol UploadReservable: class {
    var markedForUploadReserved: Bool { get set }
    func markUploadReserved()
    func resolveUploadReserved()
}

extension UploadReservable where Self: NSManagedObject {
    /// 업로드를 예약합니다.
    func markUploadReserved() {
        markedForUploadReserved = true
    }

    /// 예약 상태를 해제합니다.
    func resolveUploadReserved() {
        if markedForUploadReserved {
            markedForUploadReserved = false
        }
    }
}
