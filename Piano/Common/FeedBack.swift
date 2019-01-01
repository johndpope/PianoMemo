//
//  FeedBack.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 5..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

struct Feedback {
    static private let selection = UIImpactFeedbackGenerator()

    static func success() {
        selection.impactOccurred()
    }

//    static func error() {
//        selection.impactOccurred()
//    }
//    
//    static func warning() {
//        selection.impactOccurred()
//    }
}
