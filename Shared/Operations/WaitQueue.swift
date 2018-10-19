//
//  ReadyDelayQueue.swift
//  Piano
//
//  Created by hoemoon on 18/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

class WaitQueue: NSObject {
    private var readyQueue = [Operation]()

    private func addOperation(_ operation: Operation) {
        readyQueue.append(operation)
    }

    func enqueue(action: @escaping () -> Void) {
        let operation = BlockOperation(block: action)
        addOperation(operation)
    }
    func start() {
        OperationQueue.main.addOperations(readyQueue, waitUntilFinished: false)
    }
}
