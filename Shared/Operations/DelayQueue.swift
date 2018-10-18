//
//  DelayQueue.swift
//  Piano
//
//  Created by hoemoon on 16/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

class DelayQueue: NSObject {
    private let delayInterval: Double
    private var queue = [Operation]()
    private var timer: Timer?

    init(delayInterval: Double) {
        self.delayInterval = delayInterval
    }

    private func addOperation(_ operation: Operation) {
        queue.append(operation)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: delayInterval, repeats: false) {
            [weak self] timer in
            guard let self = self else { return }
            if let last = self.queue.last {
                OperationQueue.main.addOperation(last)
                self.queue = []
            }
        }
    }

    func enqueue(action: @escaping () -> Void) {
        let operation = BlockOperation(block: action)
        addOperation(operation)
    }
}
