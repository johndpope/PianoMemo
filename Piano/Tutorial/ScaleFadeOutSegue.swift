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
        let fromViewController = self.source
        let blurView = blurEffectView(container: fromViewController.view)
    
        fromViewController.view.superview?.insertSubview(blurView, at: 0)
        fromViewController.view.superview?.insertSubview(toViewController.view, at: 0)
        fromViewController.view.backgroundColor = UIColor.clear
        
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
            fromViewController.view.transform = CGAffineTransform(scaleX: 2, y: 2)
            fromViewController.view.layer.opacity = 0
            blurView.effect = nil
        }, completion: { success in
            blurView.willMove(toWindow: nil)
            fromViewController.present(toViewController, animated: false, completion: {
                guard let navController = toViewController as? UINavigationController else { return }
                guard let viewController = navController.viewControllers.first as? NoteCollectionViewController else { return }
                viewController.performSegue(withIdentifier: SmartWritingViewController.identifier, sender: nil)
            })
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
