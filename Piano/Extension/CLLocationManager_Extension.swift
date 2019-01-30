//
//  CLLocationManager_Extension.swift
//  Piano
//
//  Created by Kevin Kim on 30/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import CoreLocation

extension CLLocationManager {
    //위치를 항상 허용하거나, 앱을 사용중일 때 허용한 것 둘 중에 하나 키기만 하면 true
    static var hasAuthorized: Bool {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }
}
