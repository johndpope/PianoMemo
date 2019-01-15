//
//  CollectionView_extension.swift
//  Piano
//
//  Created by Kevin Kim on 15/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension CollectionView {
    enum EditingState: Int {
        case notEditing = 1000
        case editing = 2000
    }
    
    var isEditable: Bool {
        get {
            guard let state = EditingState(rawValue: self.tag) else { return false }
            return state == .editing
        } set {
            switch newValue {
            case true:
                self.tag = EditingState.editing.rawValue
            case false:
                self.tag = EditingState.notEditing.rawValue
            }
        }
    }
}
