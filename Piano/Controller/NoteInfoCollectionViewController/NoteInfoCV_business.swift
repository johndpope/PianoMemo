//
//  NoteInfoCV_business.swift
//  Piano
//
//  Created by Kevin Kim on 24/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension NoteInfoCollectionViewController {
    internal func setup() {

    }
    
    internal func setupDataSource() {
        let info7 = NoteInfo(type: .folder, note: note)
        let info8 = NoteInfo(type: .expireDate, note: note)
        let section1 = [info7, info8]

        let info5 = NoteInfo(type: .creationDate, note: note)
        let info6 = NoteInfo(type: .modifiedDate, note: note)
        let info3 = NoteInfo(type: .characterCount, note: note)
        let info4 = NoteInfo(type: .paragraphCount, note: note)
        let info1 = NoteInfo(type: .checklistCount, note: note)
        let info2 = NoteInfo(type: .checklistAchievementRate, note: note)
        let section2 = [info1, info2, info3, info4, info5, info6]

        self.dataSource.append(section1)
        self.dataSource.append(section2)
    }
}
