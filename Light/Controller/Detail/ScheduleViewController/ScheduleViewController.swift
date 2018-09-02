//
//  ScheduleViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 1..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

class ScheduleViewController: UIViewController {

    @IBOutlet weak var eventContainerView: UIView!
    @IBOutlet weak var reminderContainerView: UIView!
    @IBOutlet var segmentControl: UISegmentedControl!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.navigationItem.titleView = segmentControl
        
        let rightBarBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addItem(_:)))
        tabBarController?.navigationItem.setRightBarButtonItems([rightBarBtn], animated: true)
    }
    
    @objc private func addItem(_ button: UIBarButtonItem) {
        if segmentControl.selectedSegmentIndex != 0 {
            performSegue(withIdentifier: "ReminderPickerTableViewController", sender: nil)
        } else {
            performSegue(withIdentifier: "CalendarPickerTableViewController", sender: nil)
        }
        
        
    }

}
