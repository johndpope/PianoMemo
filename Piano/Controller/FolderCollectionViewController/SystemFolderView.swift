//
//  SystemFolderView.swift
//  Piano
//
//  Created by hoemoon on 01/02/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

protocol SystemFolderViewDelegate: class {
    func tapSystemFolder(state: NoteCollectionViewController.NoteCollectionState)
}

class SystemFolderView: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    var systemFolderStateRepresentation: NoteCollectionViewController.NoteCollectionState!

    weak var delegate: SystemFolderViewDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.addGestureRecognizer(tap)
    }

    @objc private func handleTap(_ sender: Any) {
        delegate?.tapSystemFolder(state: systemFolderStateRepresentation)
    }
}
