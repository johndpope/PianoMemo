//
//  Calendar_extention.swift
//  Light
//
//  Created by JangDoRi on 2018. 8. 29..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation

extension Calendar {

    /// 오늘의 0시 정각을 반환한다.
    var today: Date {
        let com = dateComponents([.year, .month, .day], from: Date())
        return date(from: com) ?? Date()
    }

}
