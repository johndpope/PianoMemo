//
//  Analytics_extension.swift
//  Piano
//
//  Created by 박주혁 on 04/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation
import Amplitude_iOS

/// Amplitude 커스텀 이벤트와 사용자 속성을 정의

class Analytics {

    enum UserPropertyName: String {
        case noteTotal = "note_total"
        case purchased = "purchased"
    }

    // User Property
    private static func setUserProperty(_ value: NSObject, name: String) {
        let identify = AMPIdentify.init()
        identify.set(name, value: value)
        Amplitude.instance()?.identify(identify)
    }

    public static func setUserProperty(int value: Int, forName: UserPropertyName) {
        Analytics.setUserProperty(NSNumber.init(value: value), name: forName.rawValue)
    }

    public static func setUserProperty(double value: Double, forName: UserPropertyName) {
        Analytics.setUserProperty(NSNumber.init(value: value), name: forName.rawValue)
    }

    public static func setUserProperty(string value: String, forName: UserPropertyName) {
        Analytics.setUserProperty(NSString.init(string: value), name: forName.rawValue)
    }

    private static func addUserProperty(int value: Int, forName: UserPropertyName) {
        let identify = AMPIdentify.init()
        identify.add(forName.rawValue, value: NSNumber.init(value: value))
        Amplitude.instance()?.identify(identify)
    }

    //Note: The keys should be of type NSString and the values should be of type NSString, NSNumber, NSArray, NSDictionary, or NSNull. You will see a warning if you try to use an unsupported type.

    // - MARK: Note Event
    private static func logEvent(_ name: String, properties: [String: Any]? = nil) {
        if let properties = properties {
            Amplitude.instance()?.logEvent(name, withEventProperties: properties)
        } else {
            Amplitude.instance()?.logEvent(name)
        }
    }

    /// 이벤트 프로퍼티가 없는 간단한 이벤트를 로깅할 때 사용
    public static func logEvent(eventName: String) {
        Analytics.logEvent(eventName)
    }

    /// 노트 보기
    public static func logEvent(viewNote note: Note) {
        let params: [String: Any] = [
            "note_id": note.recordID ?? "Unknown"
        ]
        Analytics.logEvent("view_note", properties: params)
    }

    //노트가 생성된 위치를 기록해두기 위한 Temp var
    static var createNoteAt: String?

    /// 노트 생성 이벤트
    public static func logEvent(createNote note: Note, size: Int = 0) {
        let params: [String: Any] = [
            "note_id": note.recordID ?? "Unknown",
            "position": Analytics.createNoteAt ?? "Unknown",
            "size": size
        ]
        Analytics.logEvent("create_note", properties: params)
        Analytics.createNoteAt = nil
    }

    /// 노트 업데이트
    public static func logEvent(updateNote note: Note) {
        let params: [String: Any] = [
            "note_id": note.recordID ?? "Unknown"
        ]
        Analytics.addUserProperty(int: 1, forName: .noteTotal)
        Analytics.logEvent("update_note", properties: params)
    }

    //노트가 생성된 위치를 기록해두기 위한 Temp var
    static var deleteNoteAt: String?

    /// 노트 삭제
    public static func logEvent(deleteNote note: Note) {
        let params: [String: Any] = [
            "note_id": note.recordID ?? "Unknown",
            "position": Analytics.deleteNoteAt ?? "Unknown"
        ]
        Analytics.addUserProperty(int: -1, forName: .noteTotal)
        Analytics.logEvent("delete_note", properties: params)
        Analytics.deleteNoteAt = nil
    }

    public static func logEvent(shareNote note: Note?, format: String) {
        let params: [String: Any] = [
            "note_id": note?.recordID ?? "Unknown",
            "format": format
        ]
        Analytics.logEvent("share_note", properties: params)
    }

    public static func logEvent(mergeNote notes: [Note]) {
        let params: [String: Any] = [
            "notes": notes.count
        ]
        Analytics.logEvent("merge_note", properties: params)
    }

    /// 노트에 태그 붙이기
    public static func logEvent(attachTagsTo note: Note, tags: String) {
        let params: [String: Any] = [
            "note_id": note.recordID ?? "Unknown",
            "tags": tags
        ]
        Analytics.logEvent("attach_tag", properties: params)
    }

    enum EditorAction: String {
        case highlight = "highlight",
        copyAll = "copy_all"
    }
    public static func logEvent(editNote note: Note?, action: EditorAction) {
        let params: [String: Any] = [
            "note_id": note?.recordID ?? "Unknown",
            "action": action.rawValue
        ]
        Analytics.logEvent("edit_note", properties: params)
    }

    public static func logEvent(tapBottomItem item: String) {
        let params: [String: Any] = [
            "button": item
        ]
        Analytics.logEvent("tap_bottom_item", properties: params)
    }

    // - MARK: ScreenView Event
    public static func logEvent(screenView screen: String) {
        let params: [String: Any] = [
            "title": screen
        ]
        Analytics.logEvent("view_screen", properties: params)
    }

    enum PurchaseStep: String {
        case alert = "viewOffer",
        tryProcess = "try",
        fail = "fail",
        success = "success"
    }

    // - MARK: Purchase Event
    public static func logEvent(purchase step: PurchaseStep, error: String? = nil) {
        switch step {
        case .alert:
            Analytics.setUserProperty(string: step.rawValue, forName: .purchased)
            Analytics.logEvent("view_offer")

        case .tryProcess:
            Analytics.setUserProperty(string: step.rawValue, forName: .purchased)
            Analytics.logEvent("try_purchase")

        case .fail:
            let params: [String: Any] = [
                "reason": error ?? "Unknown"
            ]
            Analytics.setUserProperty(string: step.rawValue, forName: .purchased)
            Analytics.logEvent("fail_purchase", properties: params)

        case .success:
            Analytics.setUserProperty(string: step.rawValue, forName: .purchased)
            Analytics.logEvent("success_purchase")
        }

    }

}
