//
//  ImageTagCell.swift
//  Piano
//
//  Created by Kevin Kim on 15/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import DifferenceKit

enum DefaultTagType {
    case clipboard
    case location
    case schedule
    
    var image: UIImage {
        switch self {
        case .clipboard:
            return UIPasteboard.general.hasStrings ? #imageLiteral(resourceName: "fullClipboard") : #imageLiteral(resourceName: "clipboard")
        case .location:
            return #imageLiteral(resourceName: "location")
        case .schedule:
            return #imageLiteral(resourceName: "schedule")
            
        }
    }
}

struct ImageTagModel: ViewModel, Collectionable {
    let type: DefaultTagType
    
    
    init(type: DefaultTagType) {
        self.type = type
    }
    
    internal func size(view: View) -> CGSize {
        return CGSize(width: 40, height: 30)
    }
    
    func didSelectItem(collectionView: CollectionView, fromVC viewController: ViewController) {
        
    }
    
//    var minimumInteritemSpacing: CGFloat = 40
    var minimumLineSpacing: CGFloat = 20
    
    
    func sectionInset(view: View) -> EdgeInsets {
        return EdgeInsets(top: 0, left: 5, bottom: 0, right: 20)
    }
}

class ImageTagModelCell: UICollectionViewCell, ViewModelAcceptable {

    var viewModel: ViewModel? {
        didSet {
            guard let imageTagModel = viewModel as? ImageTagModel else { return }
            imageView.image = imageTagModel.type.image
        }
    }
    
    @IBOutlet weak var imageView: UIImageView!
    
    

}
