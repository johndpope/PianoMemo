//
//  LotieViewController.swift
//  Piano
//
//  Created by Kevin Kim on 28/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import Lottie

class LotieViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let animationView = LOTAnimationView(name: "done")
        animationView.center = view.center
        self.view.addSubview(animationView)
//        view.addSubview(animationView)
//        animationView.translatesAutoresizingMaskIntoConstraints = false
//        animationView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
//        animationView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
//        animationView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
//        animationView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        animationView.play { [weak self] (finished) in
            guard let `self` = self else { return }
            if finished {
                self.dismiss(animated: true, completion: nil)
            }
            
        }
    }

}
