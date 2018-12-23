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
//    private func addTutorialsIfNeeded() {
//        guard keyValueStore.bool(forKey: "didAddTutorials") == false else { return }
//        do {
//            let count = try backgroundContext.count(for: LocalStorageService.allfetchRequest())
//            if count == 0 {
//                createLocally(string: "1. The quickest way to copy the text\n♩ slide texts to the left side to copy them\n✷ Tap Select on the upper right, and you can copy the text you like.\n✷ Click “Convert” on the bottom right to send the memo as Clipboard, image or PDF.\n✷ Go to “How to use” in Navigate to see further information.".loc, tags: "")
//                createLocally(string: "2. How to tag with Memo\n♩ On any memo, tap and hold the tag to paste it into the memo you want to tag with.\n✷ If you'd like to un-tag it, paste the same tag back into the memo.\n✷ Go to “How to use” in Setting to see further information.".loc, tags: "")
//                createLocally(string: "3. How to highlight\n♩ Click the ‘Highlighter’ button below.\n✷ Slide the texts you want to highlight from left to right.\n✷ When you slide from right to left, the highlight will be gone.\n✷ Go to “How to use” in Setting to see further information.".loc, tags: "")
//                createLocally(string: "4. How to use Emoji List\n♩ Use the shortcut keys (-,* etc), and put a space to make it list.\n✷ Both shortcut keys and emoji can be modified in the Customized List of the settings.".loc, tags: "")
//                createLocally(string: "5. How to add the schedules\n♩ Write down the time/details to add your schedules.\n✷ Ex: Meeting with Cocoa at 3 pm\n✷ When you write something after using shortcut keys and putting a spacing, you can also add it on reminder.\n✷ Ex: -To buy iPhone charger.".loc, tags: "") { [weak self](_) in
//                    guard let self = self else { return }
//                    self.keyValueStore.set(true, forKey: "didAddTutorials")
//                }
//            }
//        } catch {
//            print(error)
//        }
//    }
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
