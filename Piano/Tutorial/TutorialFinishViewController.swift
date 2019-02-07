//
//  TutorialFinishViewController.swift
//  Piano
//
//  Created by 박주혁 on 29/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class TutorialFinishViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UserDefaults.standard.set(true, forKey: "didFinishTutorial")
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            self.performSegue(withIdentifier: NoteCollectionViewController.identifier, sender: nil)
        }
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nav = segue.destination as? UINavigationController,
            let des = nav.viewControllers.first as? NoteCollectionViewController {
            des.isFromTutorial = true
        }
    }
}
