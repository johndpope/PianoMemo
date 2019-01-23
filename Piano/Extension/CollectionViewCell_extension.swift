//
//  CollectionViewCell_extension.swift
//  Piano
//
//  Created by Kevin Kim on 23/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension CollectionViewCell {
    var customSelectedBackgroudView: View {
        let view = View()
        view.backgroundColor = Color.selected
        return view
    }
}
