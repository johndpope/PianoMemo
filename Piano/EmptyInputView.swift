//
//  EmptyInputView.swift
//  Piano
//
//  Created by Kevin Kim on 16/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class EmptyInputView: UIView {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var addKeyboardButton: UIButton!
    
    var completionHandler: (() -> Void)?
    

    @IBAction func moveToSetting(_ sender: Any) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { [weak self] (success) in
                self?.completionHandler?()
            })
        }
        
        
    }
}
