//
//  SyncCoordinator+ObserverTokenStore.swift
//  Piano
//
//  Created by hoemoon on 26/02/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

protocol ObserverTokenStore: class {
    func addObserverToken(_ token: NSObjectProtocol)
    func removeAllObserverTokens()
}

extension SyncCoordinator: ObserverTokenStore {
    func addObserverToken(_ token: NSObjectProtocol) {
        observerTokens.append(token)
    }

    func removeAllObserverTokens() {
        observerTokens.removeAll()
    }
}
