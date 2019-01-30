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
        
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { timer in
            let rootVC = self.navigationController?.viewControllers.first
            let presentingVC = rootVC?.presentingViewController as? UINavigationController
            self.dismiss(animated: true) {
                guard let masterVC = presentingVC?.viewControllers.first as? MasterViewController else {return}
                masterVC.bottomView?.textView?.becomeFirstResponder()
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
