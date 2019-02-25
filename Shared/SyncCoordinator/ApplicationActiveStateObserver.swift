//
//  ApplicationActiveStateObserver.swift
//  Piano
//
//  Created by hoemoon on 24/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

protocol ApplicationActiveStateObserving: ObserverTokenStore {
    func perform(_ block: @escaping () -> Void)
    func applicationDidBecomeActive()
    func applicationDidEnterBackground()
}

extension ApplicationActiveStateObserving {
    private var center: NotificationCenter {
        return NotificationCenter.default
    }
    func setupApplicationActiveNotifications() {
        let didEnterBackground = center.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil, queue: nil) { [weak self] _ in
                guard let observer = self else { return }
                observer.perform {
                    observer.applicationDidEnterBackground()
                }
        }

        let didBecomeActive = center.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil, queue: nil) { [weak self] _ in
                guard let observer = self else { return }
                observer.perform {
                    observer.applicationDidBecomeActive()
                }
        }
        addObserverToken(didEnterBackground)
        addObserverToken(didBecomeActive)
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState == .active {
                self.applicationDidBecomeActive()
            }
        }
    }
}
