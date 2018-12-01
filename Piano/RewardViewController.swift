//
//  RewardViewController.swift
//  Piano
//
//  Created by Kevin Kim on 01/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class RewardViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var rewardButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var toolbar: UIToolbar!
    
    var product: Product!

    override func viewDidLoad() {
        super.viewDidLoad()
        toolbar.roundCorners([.topLeft, .topRight], radius: 10)
        setup(with: product)
    }
    
    private func setup(with product: Product) {
//        let 
    }
    
}

