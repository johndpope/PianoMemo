//
//  ReminderDetailViewController.swift
//  Piano
//
//  Created by Kevin Kim on 14/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class ReminderDetailViewController: UIViewController {

    
    @IBOutlet weak var textfield: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    


}

extension ReminderDetailViewController: UITextViewDelegate {
    
}
