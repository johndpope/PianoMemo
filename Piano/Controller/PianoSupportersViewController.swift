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
        pianoEditorView.setup(state: .readOnly, str: "Piano offers 5 benefits for Piano Supporters.\n1. We will incorporate the features based on our supporters' needs and inconveniences.\n2. You can use Piano app with the lastest features and enhancements.\n3. You can get an elegant Piano app icon, available only for Supporters.\n4. We plan to send out supporter gift boxes in the future.\n5. You can join us to build the final note app on Earth. \nTo become a Piano Supporter:\n✷ Step 1. Use Piano app a lot.\n✷ Step 2. Give us a review on the app store.\n✷ Step 3. Give us a 'Like' on the Piano Facebook page.\n✷ Step 4. Please send us the following:\n\n✷ A self introduction\n✷ What kinds of notes you usually take on the Piano app\n✷ List of pros and cons for the Piano app\n✷ What do you want to do after becoming a Piano Supporter\n\nTo our email(supporters@pianotext.com)\n\nWe will select individuals to join the team of Piano Supporters.\nWe will give you various missions and benefits every month.\n\nTogether, we can all team up to collaborate and design the next and final generation of notetaking.\nThank you 🙇‍♂️🙇‍♀️".loc)
        self.pianoEditorView = pianoEditorView

    }

}
