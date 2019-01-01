//
//  AddTagReusableView.swift
//  Piano
//
//  Created by Kevin Kim on 15/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class AddTagReusableView: UICollectionReusableView {

    @IBOutlet weak var button: UIButton!
    var action: (() -> Void)?

    @IBAction func tapPlus(_ sender: UIButton) {
        action?()
    }

}
