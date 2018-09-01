//
//  ScheduleVC_Action.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 1..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation

extension ScheduleViewController {
    @IBAction func switchSegmentControl(_ control: SegmentControl) {
        
        eventContainerView.isHidden = control.selectedSegmentIndex == 0
        reminderContainerView.isHidden = control.selectedSegmentIndex != 0
        
    }
}
