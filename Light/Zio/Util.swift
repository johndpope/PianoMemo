//
//  Util.swift
//  PianoNote
//
//  Created by 김경록 on 2018. 3. 22..
//  Copyright © 2018년 piano. All rights reserved.
//

import UIKit

class Util: NSObject {
    
    static let share = Util()
    
    func getUniqueID() -> String {
        
        let dateString = "\(Date().timeIntervalSinceReferenceDate)"
        let uuidString = UIDevice.current.identifierForVendor?.uuidString ?? "default_uuid"
        
        return (uuidString + dateString)
    }
    
}

