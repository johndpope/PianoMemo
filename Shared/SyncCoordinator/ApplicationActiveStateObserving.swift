//
//  ApplicationActiveStateObserver.swift
//  Piano
//
//  Created by hoemoon on 24/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import CoreData

/// App life cycle에 대응하는 메서드를 정의합니다.
protocol ApplicationActiveStateObserving: ObserverTokenStore {
    func perform(_ block: @escaping () -> Void)
    func applicationDidBecomeActive()
    func applicationDidEnterBackground()
}

extension ApplicationActiveStateObserving {
    private var center: NotificationCenter {
        return NotificationCenter.default
    }

    /// 옵저버를 등록합니다.
    /// syncCoordinator를 setup할때 호출됩니다.
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

extension SyncCoordinator: ApplicationActiveStateObserving {

    func applicationDidBecomeActive() {
        fetchLocallyTrackedObjects()
        fetchRemoteDataForApplicationDidBecomeActive()
    }

    func applicationDidEnterBackground() {
        //        backgroundContext.refreshAllObjects()
    }
}
