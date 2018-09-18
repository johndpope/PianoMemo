//
//  PianoCollectionReusableView.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 12..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

class PianoCollectionReusableView: UICollectionReusableView, CollectionDataAcceptable {
    var data: CollectionDatable? {
        didSet {
            guard let data = self.data else { return }
            
            if let image = data.sectionImage {
                imageView.image = image
                imageView.isHidden = false
            } else {
                imageView.isHidden = true
            }
            
            if let title = data.sectionTitle {
                label.text = title
                label.isHidden = false
            } else {
                label.isHidden = true
            }
        }
    }
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
}
