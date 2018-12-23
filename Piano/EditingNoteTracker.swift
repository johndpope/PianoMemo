//
//  EditingNoteTracker.swift
//  Piano
//
//  Created by hoemoon on 23/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

class EditingTracker {
    static let shared = EditingTracker()
    private init() {}
    var editingNote: Note?

    func setEditingNote(note: Note?) {
        editingNote = note
    }
}
