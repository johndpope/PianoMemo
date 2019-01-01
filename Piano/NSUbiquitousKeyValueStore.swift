//
//  NSUbiquitousKeyValueStore.swift
//  Piano
//
//  Created by hoemoon on 23/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

typealias KeyValueStore = NSUbiquitousKeyValueStore

private let emojiKey = "emojiTags"

extension NSUbiquitousKeyValueStore {
    var emojis: [String] {
        if let value = NSUbiquitousKeyValueStore.default.array(forKey: emojiKey) as? [String] {
            return value
            //                return value.sorted(by: emojiSorter)
        } else {
            return ["❤️", "🔒"]
        }
    }

    func updateEmojis(newValue: [String]) {
        NSUbiquitousKeyValueStore.default.set(newValue, forKey: emojiKey)
        NotificationCenter.default.post(
            name: NSNotification.Name.refreshTextAccessory,
            object: nil
        )
    }
}
