//
//  NSEntityDescription.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 6..
//

import CoreData

internal extension NSEntityDescription {
    
    internal var isCloudable: Bool {
        return (name != nil) && attributesByName.keys.contains(KEY_RECORD_DATA)
    }
    
}
