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

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UserDefaults.standard.set(true, forKey: "didFinishTutorial")
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
            let presentingVC = self.presentingViewController as? UINavigationController
            self.dismiss(animated: true) {
                guard let noteCollectionVC = presentingVC?.viewControllers.first as? NoteCollectionViewController else {return}
                noteCollectionVC.performSegue(withIdentifier: SmartWritingViewController.identifier, sender: nil)
            }
        }
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
