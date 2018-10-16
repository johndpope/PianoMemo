//
//  DelayQueue.swift
//  Piano
//
//  Created by hoemoon on 16/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

class DelayQueue: NSObject {
    private let delayCounter: Int
    private lazy var serialQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    private var readyQueue = [Operation]()
    private var timer: Timer?

    init(delayCounter: Int) {
        self.delayCounter = delayCounter
    }

    func addOperation(_ operation: Operation) {
        guard let interval = TimeInterval(exactly: delayCounter) else { return }
        readyQueue.append(operation)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) {
            [weak self] timer in
            guard let self = self else { return }
            if let last = self.readyQueue.last {
                OperationQueue.main.addOperation(last)
                self.readyQueue = []
            }
        }
    }

    func addOperation(action: @escaping () -> Void) {
        let operation = DelayOperation(action: action)
        addOperation(operation)
    }
}

class DelayOperation: Operation {
    private let action:() -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    override func main() {
        action()
    }
}
