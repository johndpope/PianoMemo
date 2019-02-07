//
//  ScaleFadeOutSegue.swift
//  Piano
//
//  Created by 박주혁 on 07/02/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class ScaleFadeOutSegue: UIStoryboardSegue {
    
    override func perform() {
        animate()
    }
    
    func animate() {
        let toViewController = self.destination
        guard let fromViewController = self.source
        let blurView = blurEffectView(container: fromViewController.view)
    
        fromViewController.view.superview?.insertSubview(toViewController.view, at: 0)
        fromViewController.view.insertSubview(blurView, at: 0)
        fromViewController.view.backgroundColor = UIColor.clear
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            fromViewController.view.transform = CGAffineTransform(scaleX: 3, y: 3)
            fromViewController.view.subviews.last?.layer.opacity = 0
            blurView.effect = nil
        }, completion: { success in
            fromViewController.present(toViewController, animated: false, completion: nil)
        })
    }
    
    func blurEffectView(container: UIView) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = container.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return blurEffectView
    }
}
