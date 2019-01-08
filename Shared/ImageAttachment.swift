//
//  ImageAttachment.swift
//  Piano
//
//  Created by hoemoon on 08/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import CoreData

public class ImageAttachment: NSManagedObject {
    @NSManaged public var localID: String?
    @NSManaged public var imageData: NSData?
}

extension ImageAttachment {
    enum LocalKey: String {
        case localID
        case imageData
    }
}

extension ImageAttachment: Managed {}
