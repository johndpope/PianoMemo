//
//  PhotoDetailViewController.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import Photos

class PhotoDetailViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    var image: UIImage?
    var asset: PHAsset?
    
    private let imageView = UIImageView()
    
    private lazy var imageManager = PHCachingImageManager.default()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        tap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(tap)
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)
        setImage()
    }
    
    @objc private func tap(_ gesture: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.3) {
            self.scrollView.zoomScale = 1
        }
    }
    
    private func setImage() {
        if let image = image {
            imageView.image = image
        } else if let asset = asset {
            requestImage(asset) { (image, error) in
                self.imageView.image = image
            }
        } else {
            // Error...
        }
    }
    
    private func requestImage(_ asset: PHAsset, completion: @escaping (UIImage?, [AnyHashable : Any]?) -> ()) {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        imageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options, resultHandler: completion)
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
