//
//  UserDefaults.swift
//  Piano
//
//  Created by hoemoon on 14/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CloudKit

extension UserDefaults {
    static func getServerChangedToken(key: String) -> CKServerChangeToken? {
        if let data = standard.data(forKey: key),
            let token = NSKeyedUnarchiver.unarchiveObject(with: data) as? CKServerChangeToken {
            return token
        }
        return nil
    }

    static func setServerChangedToken(key: String, token: CKServerChangeToken?) {
        guard let token = token else { return }
        let data = NSKeyedArchiver.archivedData(withRootObject: token)
        standard.set(data, forKey: key)
    }

    static func getUserIdentity() -> CKUserIdentity? {
        let key = "userIdentity"
        if let data = standard.data(forKey: key),
            let record = NSKeyedUnarchiver.unarchiveObject(with: data) as? CKUserIdentity {
            return record
        }
        return nil
    }
    static func setUserIdentity(identity: CKUserIdentity?) {
        guard let identity = identity else { return }
        let data = NSKeyedArchiver.archivedData(withRootObject: identity)
        standard.set(data, forKey: "userIdentity")
    }
}