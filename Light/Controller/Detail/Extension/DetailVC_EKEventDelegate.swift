//
//  DetailVC_EKEventDelegate.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 12..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import EventKitUI

extension DetailViewController: EKEventViewDelegate {
    func eventViewController(_ controller: EKEventViewController, didCompleteWith action: EKEventViewAction) {
        controller.dismiss(animated: true, completion: nil)
    }
}
