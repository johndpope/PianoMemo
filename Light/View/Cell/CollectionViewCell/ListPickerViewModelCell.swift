//
//  ListPickerViewModelCell.swift
//  Piano
//
//  Created by Kevin Kim on 18/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

struct ListPickerViewModel: CollectionDatable {
    
    let emoji: String
    var sectionTitle: String?
    var sectionImage: Image?
    var sectionIdentifier: String?
    
    
    init(emoji: String, sectionTitle: String? = nil, sectionImage: Image? = nil, sectionIdentifier: String? = nil) {
        self.emoji = emoji
        self.sectionTitle = sectionTitle
        self.sectionImage = sectionImage
        self.sectionIdentifier = sectionIdentifier
    }
    
    func didSelectItem(fromVC viewController: ViewController) {
    }
    
    func didDeselectItem(fromVC viewController: ViewController) {
        
    }
    
    func size(maximumWidth: CGFloat) -> CGSize {
        
        var n = 1
        var usedWidth: CGFloat = 0
        while true {
            
            let width: CGFloat = CGFloat(50 * n + 8 * (n + 1))
            if width > maximumWidth { break }
            usedWidth = width
            n += 1
        }
        
        let plusFloat = (maximumWidth - usedWidth) / CGFloat(n)
        let plusInt = Int(plusFloat)
        
        return CGSize(width: 50 + plusInt, height: 50 + plusInt)
    }
    
    var headerSize: CGSize = CGSize(width: 100, height: 0)
    var sectionInset: EdgeInsets = EdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    var minimumInteritemSpacing: CGFloat = 8
    var minimumLineSpacing: CGFloat = 8
    
    
}

class ListPickerViewModelCell: UICollectionViewCell, CollectionDataAcceptable {
    var data: CollectionDatable? {
        didSet {
            guard let viewModel = data as? ListPickerViewModel else { return }
            label.text = viewModel.emoji
        }
    }
    
    @IBOutlet weak var label: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        selectedBackgroundView = borderView
    }
    
    var borderView: UIView {
        let view = UIView()
        view.backgroundColor = Color.clear
        view.cornerRadius = 15
        view.borderWidth = 2
        view.borderColor = Color(red: 62/255, green: 154/255, blue: 255/255, alpha: 0.8)
        return view
    }
    
    
    
}
