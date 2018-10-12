//
//  FeedBack.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 5..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

struct Feedback {
    static private let selection = UIImpactFeedbackGenerator(style: UIImpactFeedbackGenerator.FeedbackStyle.medium)
    
    static func success() {
        selection.impactOccurred()
//        selection.selectionChanged()
    }
    
    static func error() {
        selection.impactOccurred()
//        selection.selectionChanged()
    }
    
    static func warning() {
        selection.impactOccurred()
//        selection.selectionChanged()
    }
}
