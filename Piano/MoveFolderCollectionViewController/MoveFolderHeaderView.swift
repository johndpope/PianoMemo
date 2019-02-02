//
//  MoveFolderHeaderView.swift
//  Piano
//
//  Created by hoemoon on 29/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class MoveFolderHeaderView: UICollectionReusableView {
    @IBOutlet weak var firstFakeView: FakeNoteView!
    @IBOutlet weak var secondFakeView: UIView!
    @IBOutlet weak var thirdFakeView: UIView!

    @IBOutlet weak var firstItemHeight: NSLayoutConstraint!

    var notes: [Note]? {
        didSet {
            guard let notes = notes else { return }
            switch notes.count {
            case 1:
                secondFakeView.isHidden = true
                thirdFakeView.isHidden = true
                firstItemHeight.constant -= 5
            case 2:
                thirdFakeView.isHidden = true
                firstItemHeight.constant -= 10
            case 3:
                firstItemHeight.constant -= 15
            default:
                break
            }
            firstFakeView.note = notes.first
        }
    }
}
