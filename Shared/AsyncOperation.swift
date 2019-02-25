//
//  AsyncOperation.swift
//  Piano
//
//  Created by hoemoon on 09/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

/// 비동기 작업을 Operation으로 처리할 경우 사용할 수 있는 클래스 입니다.
/// https://www.notion.so/pianote/Advanced-NSOperations-WWDC-2015-00a6438f8f564379a1810d9a7b161c2f
/// 페이지의 마지막 부분에 자세한 설명이 포함되어 있습니다.
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
