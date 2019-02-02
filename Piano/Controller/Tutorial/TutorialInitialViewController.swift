//
//  TutorialInitialViewController.swift
//  Piano
//
//  Created by 박주혁 on 29/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class TutorialInitialViewController: UIViewController {

    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var divider: UIView!
    @IBOutlet weak var subHeader: UILabel!

    @IBOutlet weak var note0: UIView!
    @IBOutlet weak var note1: UIView!
    @IBOutlet weak var note2: UIView!

    @IBOutlet weak var nextBtn: UIButton!

    var headerArray: [UIView] = []
    var noteArray: [UIView] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        headerArray = [header, divider, subHeader]
        noteArray = [note0, note1, note2]

        for view in headerArray {
            view.layer.opacity = 0
        }

        for note in noteArray {
            note.layer.opacity = 0
            note.layer.masksToBounds = false
            note.layer.shadowColor = UIColor.lightGray.cgColor
            note.layer.shadowOffset = CGSize(width: 0, height: 2)
            //note.layer.shadowRadius = 10
            note.layer.shadowOpacity = 0.2
        }

        nextBtn.layer.opacity = 0
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        queueNoteAnimation()
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            self.queueHeaderAnimation()
            self.queueButtonAnimation()
        }
    }

    func queueHeaderAnimation() {
        for (index, view) in headerArray.enumerated() {
            let interval = 0.3 * Double(index)
            UIView.animate(withDuration: 0.8, delay: interval, options: .curveEaseIn, animations: {
                view.layer.opacity = 1
            })
        }
    }

    func queueNoteAnimation() {
        for (index, note) in noteArray.enumerated() {
            let interval = 0.2 * Double(index)
            note.center.y += 30
            UIView.animate(withDuration: 1, delay: interval, options: .curveEaseOut, animations: {
                note.center.y -= 30
                note.layer.opacity = 1
            })
        }
    }

    func queueButtonAnimation() {
        UIView.animate(withDuration: 0.8, delay: 0, options: .curveEaseIn, animations: {
            self.nextBtn.layer.opacity = 1
        })
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
