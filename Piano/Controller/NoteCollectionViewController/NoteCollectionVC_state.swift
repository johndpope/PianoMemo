//
//  NoteCollectionVC_state.swift
//  Piano
//
//  Created by Kevin Kim on 18/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension NoteCollectionViewController {
    //view의 state를 변경하는 건, 전부 이 곳에서 처리
    enum NoteCollectionState {
        case all
        case folder(Folder)
        case lock
        case trash
        //TODO: photo, calendar ..
    }
}
