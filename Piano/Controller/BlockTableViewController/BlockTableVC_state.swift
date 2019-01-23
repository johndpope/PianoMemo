//
//  BlockTableVC_state.swift
//  Piano
//
//  Created by Kevin Kim on 18/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension BlockTableViewController {
    enum BlockTableState: Equatable {
        case normal(BlockTableDetailState)
        case removed

        enum BlockTableDetailState {
            case read
            case piano
            case editing
            case typing
        }
    }

}
