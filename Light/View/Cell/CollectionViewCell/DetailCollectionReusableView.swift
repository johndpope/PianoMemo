//
//  DetailCollectionReusableView.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 12..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

class DetailCollectionReusableView: UICollectionReusableView, CollectionDataAcceptable {
    var data: CollectionDatable? {
        didSet {
            guard let data = self.data else { return }
            imageView.image = data.sectionImage
            label.text = data.sectionTitle
        }
    }
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
}
