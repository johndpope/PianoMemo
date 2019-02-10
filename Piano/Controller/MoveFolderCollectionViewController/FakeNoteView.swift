//
//  FakeNoteView.swift
//  Piano
//
//  Created by hoemoon on 29/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class FakeNoteView: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!

    var note: Note? {
        didSet {
            guard let note = note else { return }
            titleLabel.text = note.title
            subtitleLabel.text = note.subTitle
            dateLabel.text = DateFormatter.sharedInstance.string(from: note.modifiedAt ?? Date())
        }
    }
}
