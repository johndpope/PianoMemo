//
//  LocalStorageService.swift
//  Piano
//
//  Created by hoemoon on 26/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation
import CoreData
import CloudKit
import Reachability

/// 로컬 저장소 상태를 변화시키는 모든 인터페이스 제공

//class LocalStorageService: NSObject {
//    var didDelayedTasks = false
//
//    private lazy var reachability = Reachability()
//
//    func setup() {
//        registerReachabilityNotification()
//    }
//
//    func processDelayedTasks() {
//        if didDelayedTasks == false {
//            addTutorialsIfNeeded()
//            migrateEmojiTags()
//            didDelayedTasks = true
//        }
//    }
//
//    func registerReachabilityNotification() {
//        guard let reachability = reachability else { return }
//        reachability.whenReachable = {
//            [weak self] reachability in
////            self?.handlerNotUploaded()
//        }
//        reachability.whenUnreachable = {
//            [weak self] reachability in
//            self?.didHandleNotUploaded = false
//        }
//        do {
//            try reachability.startNotifier()
//        } catch {
//            print(error)
//        }
//    }
//}
//
//extension LocalStorageService {
//
//
//    private func migrateEmojiTags() {
//        if let oldEmojis = UserDefaults.standard.value(forKey: "tags") as? [String] {
//            let filtered = oldEmojis.filter { !emojiTags.contains($0) }
//            var currentEmojis = emojiTags
//            currentEmojis.append(contentsOf: filtered)
//            emojiTags = currentEmojis
//            UserDefaults.standard.removeObject(forKey: "tags")
//        }
//    }
//
//}
