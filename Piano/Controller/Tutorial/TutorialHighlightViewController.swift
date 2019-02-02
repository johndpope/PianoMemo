//
//  TutorialHighlightViewController.swift
//  Piano
//
//  Created by 박주혁 on 29/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class TutorialHighlightViewController: UIViewController {

    @IBOutlet weak var textView: BlockTextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let pianoControl = textView.createSubviewIfNeeded(PianoControl.self),
            let pianoView = self.navigationController?.view.subView(PianoView.self) else { return }

        pianoControl.attach(on: textView)
        pianoControl.textView = textView
        pianoControl.pianoView = pianoView
        // Do any additional setup after loading the view.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
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
