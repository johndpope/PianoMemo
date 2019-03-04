//
//  UploadReservable.swift
//  Piano
//
//  Created by hoemoon on 23/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData

/// 원격 저장소 업로드를 예약하는 기능을 정의하는 프로토콜
/// -Uploader changeProcessor들은 이 프로퍼티가 true인 객체들을 업로드가 필요하다고 판단합니다.
protocol UploadReservable: class {
    var markedForUploadReserved: Bool { get set }
    func markUploadReserved()
    func resolveUploadReserved()
}

extension UploadReservable where Self: NSManagedObject {
    /// -Handler 단위에서 이 프로퍼티를 변경해서 업로드를 예약합니다.
    func markUploadReserved() {
        markedForUploadReserved = true
    }

    /// Upload가 성공하게 되면, 원래대로 돌려놓습니다.
    /// -Uploader changeProcessor가 더 이상 추적하지 않습니다.
    func resolveUploadReserved() {
        if markedForUploadReserved {
            markedForUploadReserved = false
        }
    }
}
