//
//  TutorialEmojiListViewController.swift
//  Piano
//
//  Created by 박주혁 on 29/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class TutorialEmojiListViewController: UIViewController {

    var pianoEditorView: PianoEditorView!
    @IBOutlet weak var containerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        // Do any additional setup after loading the view.
    }
    
    private func setup() {
        guard let pianoEditorView = containerView.createSubviewIfNeeded(PianoEditorView.self) else { return }
        containerView.addSubview(pianoEditorView)
        
        pianoEditorView.detailToolbar.isHidden = true
        pianoEditorView.tableView.isScrollEnabled = false
        
        pianoEditorView.translatesAutoresizingMaskIntoConstraints = false
        pianoEditorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        pianoEditorView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        pianoEditorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        pianoEditorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        pianoEditorView.setup(state: .readOnly, str: "✷ Step 1. Use Piano app a lot.\n✷ Step 2. Give us a review on the app store.\n✷ Step 3. Give us a 'Like' on the Piano Facebook page.\n✷ Step 4. Please send us the following:\n\n✷ A self introduction\n✷ What kinds of notes you usually take on the Piano app\n✷ List of pros and cons for the Piano app 🙇‍♂️🙇‍♀️".loc)
        
        pianoEditorView.tableView.allowsSelection = true
        
        self.pianoEditorView = pianoEditorView
    }
    
    @IBAction private func didTap() {
        print("tap")
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
