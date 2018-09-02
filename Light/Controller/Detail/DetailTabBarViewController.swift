//
//  DetailTabBarViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 29..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

class DetailTabBarViewController: UITabBarController {

    var note: Note!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.items?[0].title = "memo".loc
        tabBar.items?[1].title = "event".loc
        tabBar.items?[2].title = "contact".loc
        tabBar.items?[3].title = "photo".loc
        tabBar.items?[4].title = "mail".loc
    }

}
