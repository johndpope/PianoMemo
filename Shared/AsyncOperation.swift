//
//  AsyncOperation.swift
//  Piano
//
//  Created by hoemoon on 09/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

/**
 The subclass of `Operation` from which all other operations should be derived.
 This class adds both Conditions and Observers, which allow the operation to define
 extended readiness requirements, as well as notify many interested parties
 about interesting operation state changes
 */

class AsyncOperation: Operation {
    enum State: String {
        case Ready, Executing, Finished
        fileprivate var keyPath: String {
            return "is" + rawValue
        }
    }
    var state = State.Ready {
        willSet {
            willChangeValue(forKey: newValue.keyPath)
            willChangeValue(forKey: state.keyPath)
        }
        didSet {
            didChangeValue(forKey: oldValue.keyPath)
            didChangeValue(forKey: state.keyPath)
        }
    }

    override var isReady: Bool {
        return super.isReady && state == .Ready
    }
    override var isExecuting: Bool {
        return state == .Executing
    }
    override var isFinished: Bool {
        return state == .Finished
    }
    override func start() {
        if isCancelled {
            state = .Finished
            return
        }
        main()
        state = .Executing
    }
    override func cancel() {
        state = .Finished
    }
}
