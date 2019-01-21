//
//  BlockTableVC_navigationbar.swift
//  Piano
//
//  Created by Kevin Kim on 18/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension BlockTableViewController {
    
    internal func setupNavigationBar() {
        navigationItem.titleView = titleView
        navigationItem.setLeftBarButtonItems(leftBarBtnItems, animated: true)
        navigationItem.setRightBarButtonItems(rightBarBtnItems, animated: true)
    }
}

extension BlockTableViewController {
    private var leftBarBtnItems: [BarButtonItem]? {
        guard blockTableState == .normal(.piano) else { return nil }
        return [
            BarButtonItem(title: " ",
                          style: .plain,
                          target: nil,
                          action: nil)]
    }
    
    private var titleView: View? {
        guard blockTableState == .normal(.piano) else { return nil }
        return view.createSubviewIfNeeded(PianoTitleView.self)
    }
    
    private var rightBarBtnItems: [BarButtonItem]? {
        guard blockTableState == .normal(.editing)
            || blockTableState == .normal(.read) else { return nil }
        return [editButtonItem]
    }
}
