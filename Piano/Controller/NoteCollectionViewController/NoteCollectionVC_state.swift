//
//  NoteCollectionVC_state.swift
//  Piano
//
//  Created by Kevin Kim on 18/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation
import CoreData

extension NoteCollectionViewController {
    //view의 state를 변경하는 건, 전부 이 곳에서 처리
    enum NoteCollectionState {
        case all
        case folder(Folder)
        case locked
        case removed
        //TODO: photo, calendar ..
        
        internal var noteRequest: NSFetchRequest<Note> {
            switch self {
            case .all:
                return Note.allNotesRequest
            case .folder(let folder):
                return Note.folderNotesRequest(folder)
            case .locked:
                return Note.lockedNotesRequest
            case .removed:
                return Note.removedNotesRequest
            }
        }
        
        internal var cache: String {
            switch self {
            case .all:
                return "All Notes"
            case .folder(let folder):
                //TODO: folder에 대한 캐싱처리
                return ""
            case .locked:
                return "Locked Notes"
            case .removed:
                return "Removed Notes"
            }
        }
    }
}
