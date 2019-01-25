//
//  ShareNoteCV_business.swift
//  Piano
//
//  Created by Kevin Kim on 24/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension ShareNoteCollectionViewController {
    internal func setup() {
        
    }
    
    internal func setupDataSource() {
        let clipboard = ShareNoteType.clipboard
        let image = ShareNoteType.image
        let pdf = ShareNoteType.pdf
        dataSource.append([clipboard, image, pdf])
    }
}
