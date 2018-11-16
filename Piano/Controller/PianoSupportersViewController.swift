//
//  PianoSupportersViewController.swift
//  Piano
//
//  Created by Kevin Kim on 04/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class PianoSupportersViewController: UIViewController {

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
        pianoEditorView.setup(state: .readOnly, str: "supportersText".loc)
        self.pianoEditorView = pianoEditorView
        
    }

    
}
