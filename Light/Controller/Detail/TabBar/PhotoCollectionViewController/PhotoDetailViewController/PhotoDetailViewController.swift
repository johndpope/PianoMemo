//
//  PhotoDetailViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

class PhotoDetailViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        tap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(tap)
        imageView.image = image
    }
    
    @objc private func tap(_ gesture: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.3) {
            self.scrollView.zoomScale = 1
        }
    }
    
}

extension PhotoDetailViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        imageToFit(with: scrollView.zoomScale)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageToFit()
    }
    
    private func imageToFit(with zoom: CGFloat = 1) {
        let width = scrollView.bounds.width * zoom
        let height = scrollView.bounds.height * zoom
        let x = scrollView.bounds.width / 2 - width / 2
        let y = scrollView.bounds.height / 2 - height / 2
        imageView.frame = CGRect(x: (x <= 0) ? 0 : x, y: (y <= 0) ? 0 : y, width: width, height: height)
    }
    
}
