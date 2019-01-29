//
//  MoveFolderHeaderView.swift
//  Piano
//
//  Created by hoemoon on 29/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class MoveFolderHeaderView: UIView {
    func setup(notes: [Note]) {
        var constant: CGFloat = 15
        translatesAutoresizingMaskIntoConstraints = false

        for (index, note) in notes.enumerated() where index < 3 {
            let fake = FakeNoteView(note: note)
            addSubview(fake)
            NSLayoutConstraint.activate([
                fake.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                fake.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: constant),
                fake.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -constant - 10),
                fake.heightAnchor.constraint(equalToConstant: 100)
                ])
            constant -= 5
        }
    }
}
