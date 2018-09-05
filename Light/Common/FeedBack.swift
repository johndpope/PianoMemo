//
//  FeedBack.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 5..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

struct Feedback {
    static private let notification = UINotificationFeedbackGenerator()
    
    static func success() {
        notification.notificationOccurred(.success)
    }
    
    static func error() {
        notification.notificationOccurred(.error)
    }
    
    static func warning() {
        notification.notificationOccurred(.warning)
    }
}
