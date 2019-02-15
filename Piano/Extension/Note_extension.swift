//
//  Note_extension.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 30..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import EventKit
import Contacts
import ContactsUI
import Photos
import CloudKit
import MobileCoreServices

extension Note {
    public static func canHandle(_ session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSString.self)
    }
}

extension Note: Managed {}
