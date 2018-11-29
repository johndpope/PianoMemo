//
//  PurchaseManager.swift
//  Piano
//
//  Created by hoemoon on 28/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

class PurchaseManager {
    static let shared = PurchaseManager()

    private init() {}

    private let storeKey = "PurchaseManager"
    private let keyValueStore = NSUbiquitousKeyValueStore.default

    func purchase(product: Product) {
        if let old = keyValueStore.array(forKey: storeKey) as? [String] {
            var set = Set(old)
            set.insert(product.id)
            keyValueStore.set(Array(set), forKey: storeKey)
        } else {
            let new = [product.id]
            keyValueStore.set(new, forKey: storeKey)
        }
        keyValueStore.synchronize()
    }

    var purchasedIDs: [String] {
        if let array = keyValueStore.array(forKey: storeKey) as? [String] {
            return array
        }
        return []
    }
}
