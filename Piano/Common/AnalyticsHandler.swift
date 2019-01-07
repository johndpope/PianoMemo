//
//  Analytics_extension.swift
//  Piano
//
//  Created by 박주혁 on 04/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation
import Firebase

/// Firebase Analytics 클래스에서 커스텀 이벤트와 사용자 속성을 정의

class AnalyticsHandler {
    enum UserPropertyName: String {
        case noteCount = "note_count"
    }

    enum EventName: String {
        case creatNote = "create_note",
        updateNote = "update_note",
        deleteNote = "delete_note",
        viewNote = "view_note",
        shareNote = "share_note",
        editNoteHighlight = "edit_note_highlight",
        attachTag = "attach_tag",
        createTag = "create_tag",
        error = "error"
    }

    public static func setUserProperty(_ value: String?, forName: UserPropertyName) {
        Analytics.setUserProperty(value, forName: forName.rawValue)
    }

    public static func logEvent(_ name: EventName, params: [String: Any]?) {
        Analytics.logEvent(name.rawValue, parameters: params)
    }
}
