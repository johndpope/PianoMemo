//
//  TrashDetailViewController.swift
//  Piano
//
//  Created by Kevin Kim on 09/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class TrashDetailViewController: UIViewController {

    var note: Note!
    var pianoEditorView: PianoEditorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()

    }

    private func setup() {
        guard let pianoEditorView = view.createSubviewIfNeeded(PianoEditorView.self) else { return }
        view.addSubview(pianoEditorView)
        pianoEditorView.translatesAutoresizingMaskIntoConstraints = false
        pianoEditorView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pianoEditorView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        pianoEditorView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pianoEditorView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        pianoEditorView.setup(state: .trash, viewController: self, note: note)
        self.pianoEditorView = pianoEditorView

    }
}
