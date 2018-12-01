//
//  RewardViewController.swift
//  Piano
//
//  Created by Kevin Kim on 01/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
/**
 갯수를 미리 측정해서 
 
 */

class RewardViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var rewardButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var toolbar: UIToolbar!

    override func viewDidLoad() {
        super.viewDidLoad()
        toolbar.roundCorners([.topLeft, .topRight], radius: 10)
    }
    
    
    
}

