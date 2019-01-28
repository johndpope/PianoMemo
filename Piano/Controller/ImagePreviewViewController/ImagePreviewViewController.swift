//
//  ImagePreviewViewController.swift
//  Piano
//
//  Created by Kevin Kim on 25/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class ImagePreviewViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewHeightAnchor: NSLayoutConstraint!
    var note: Note!
    var jpegData: Data? {
        get {
            guard let image = imageView.image,
                let jpegData = image.jpegData(compressionQuality: 1.0) else { return nil }
            return jpegData
        } set {
            guard let jpegDAta = newValue,
                let image = UIImage(data: jpegDAta) else { return }
            
            imageViewHeightAnchor.constant = view.bounds.size.width / image.size.width * image.size.height
            
            imageView.image = image
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showImage()
        
    }

}
