//
//  TutorialInitialViewController.swift
//  Piano
//
//  Created by 박주혁 on 29/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class TutorialInitialViewController: UIViewController {

    @IBOutlet weak var note0: UIView!
    @IBOutlet weak var note1: UIView!
    @IBOutlet weak var note2: UIView!
    
    var noteArray: [UIView] = []
    override func viewDidLoad() {
        super.viewDidLoad()

        noteArray = [note0, note1, note2]
        for note in noteArray {
            note.layer.opacity = 0
            note.layer.shadowColor = UIColor.gray.cgColor
            note.layer.shadowOffset = CGSize(width: 4, height: 4)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        for (index, note) in noteArray.enumerated() {
            let interval = 0.2 * Double(index)
            note.center.y += 30
            UIView.animate(withDuration: 1, delay: interval, options: .curveEaseOut, animations: {
                note.center.y -= 30
                note.layer.opacity = 1
            })
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
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
