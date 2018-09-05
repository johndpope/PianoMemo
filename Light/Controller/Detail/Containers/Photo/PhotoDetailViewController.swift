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
    
    private lazy var imageManager = PHCachingImageManager.default()
    private let imageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setImage()
        setDoubleTap()
    }
    
    private func setImage() {
        if let image = image {
            imageView.contentMode = .scaleAspectFit
            scrollView.addSubview(imageView)
            imageView.image = image
        } else if let asset = asset {
            requestImage(asset) { (image, error) in
                self.imageView.contentMode = .scaleAspectFit
                self.scrollView.addSubview(self.imageView)
                self.imageView.image = image
                self.imageToFit()
            }
        } else {
            //...
        }
    }
    
    private func requestImage(_ asset: PHAsset, completion: @escaping (UIImage?, [AnyHashable : Any]?) -> ()) {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        imageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize,
                                  contentMode: .aspectFit, options: options, resultHandler: completion)
    }
    
    private func setDoubleTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        tap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(tap)
    }
    
    @objc private func tap(_ gesture: UITapGestureRecognizer) {
        let touchedLocation = gesture.location(ofTouch: 0, in: scrollView)
        if scrollView.zoomScale == 1 && imageView.frame.contains(touchedLocation) {
            zoom(to: touchedLocation)
        } else {
            scrollView.setZoomScale(1, animated: true)
        }
    }
    
    private func zoom(to location: CGPoint) {
        let zoom: CGFloat = 5
        let width = imageView.bounds.size.width / zoom
        let height = imageView.bounds.size.height / zoom
        let x = location.x - (width / 2)
        let y = location.y - (height / 2)
        scrollView.zoom(to: CGRect(x: x, y: y, width: width, height: height), animated: true)
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
        guard let imageSize = imageView.image?.size else {return}
        let ratio = scrollView.bounds.height * 100 / imageSize.height
        let width = (imageSize.width * ratio / 100) * zoom
        let height = scrollView.bounds.height * zoom
        let x = scrollView.bounds.width / 2 - width / 2
        let y = scrollView.bounds.height / 2 - height / 2
        imageView.frame = CGRect(x: (x <= 0) ? 0 : x,
                                 y: (y <= 0) ? 0 : y,
                                 width: width, height: height)
    }
    
}
