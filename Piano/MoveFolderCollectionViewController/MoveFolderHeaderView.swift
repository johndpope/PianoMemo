//
//  MoveFolderHeaderView.swift
//  Piano
//
//  Created by hoemoon on 29/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class MoveFolderHeaderView: UICollectionReusableView {
    @IBOutlet weak var firstView: UIView!
    @IBOutlet weak var secondView: UIView!
    @IBOutlet weak var thirdView: FakeNoteView!

    var notes: [Note]? {
        didSet {
            guard let notes = notes else { return }
            thirdView.note = notes.first
            switch notes.count {
            case 1:
                firstView.isHidden = true
                secondView.isHidden = true
            case 2:
                firstView.isHidden = true
            default:
                break
            }
        }
    }
}
