//
//  Logger.swift
//  Piano
//
//  Created by hoemoon on 22/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

class Logger: NSObject {
    private let key = "timeLog"
    private let keyValueStore = NSUbiquitousKeyValueStore.default
    private var timer: Timer?

    static let shared = Logger()

    private override init() {
        super.init()
    }

    var loggedSeconds: Int {
        return Int(self.keyValueStore.longLong(forKey: key))
    }

    var formattedLog: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: TimeInterval(loggedSeconds)) ?? ""
    }

    func start() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
            [weak self] timer in
            guard let self = self else { return }
            let oldValue = self.keyValueStore.longLong(forKey: self.key)
            self.keyValueStore.set(oldValue + Int64(1), forKey: self.key)
        }
    }

    func stop() {
        timer?.invalidate()
        keyValueStore.synchronize()
    }
}
