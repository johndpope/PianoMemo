//
//  UnlockManager.swift
//  Piano
//
//  Created by hoemoon on 28/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

class UnlockManager {
    static let shared = UnlockManager()

    private init() {}

    enum ItemKey: String {
        case unlock1
        case unlock2
        case unlock3
        case unlock4
    }

    private let storeKey = "UnlockHistory"
    private let keyValueStore = NSUbiquitousKeyValueStore.default

    func unlock(key: ItemKey) {
        if let old = keyValueStore.array(forKey: storeKey) as? [String] {
            var set = Set(old)
            set.insert(key.rawValue)
            keyValueStore.set(Array(set), forKey: storeKey)
        } else {
            let new = [key.rawValue]
            keyValueStore.set(new, forKey: storeKey)
        }
        keyValueStore.synchronize()
    }

    var unlockedItems: [String] {
        if let array = keyValueStore.array(forKey: storeKey) as? [String] {
            return array
        }
        return []
    }
}
