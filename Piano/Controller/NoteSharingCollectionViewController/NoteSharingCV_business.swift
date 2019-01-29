//
//  NoteSharingCV_business.swift
//  Piano
//
//  Created by Kevin Kim on 24/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension NoteSharingCollectionViewController {
    internal func setup() {

    }

    internal func setupDataSource() {
        let clipboard = NoteSharingType.clipboard
        let image = NoteSharingType.image
        let pdf = NoteSharingType.pdf
        dataSource.append([clipboard, image, pdf])
    }
}
