//
//  TagCell.swift
//  Piano
//
//  Created by Kevin Kim on 30/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit


struct TagModel: ViewModel, Collectionable {
    let string: String
    
    init(string: String) {
        self.string = string
    }
    
    internal func size(view: View) -> CGSize {
        var size = NSAttributedString(string: self.string, attributes: [.font : Font.systemFont(ofSize: 13, weight: .semibold)]).size()
        let leadingMargin = 11
        let topMargin = 8
        size.width += CGFloat(leadingMargin * 2)
        size.height += CGFloat(topMargin * 2)
        print(size)
        return size
    }
    
    func didSelectItem(collectionView: CollectionView, fromVC viewController: ViewController) {
        
    }
    
    func sectionInset(view: View) -> EdgeInsets {
        return EdgeInsets.zero
    }
}

class TagModelCell: UICollectionViewCell, ViewModelAcceptable {
    
    var viewModel: ViewModel? {
        didSet {
            guard let viewModel = viewModel as? TagModel else { return }
            label.text = viewModel.string
            selectedBackgroundView?.cornerRadius = viewModel.size(view: self).height / 2
        }
    }

    @IBOutlet weak var label: UILabel!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        selectedBackgroundView = customSelectedBackgroudView
    }
    
    var customSelectedBackgroudView: UIView {
        let view = UIView()
        view.backgroundColor = Color.selected
        view.cornerRadius = 15
        return view
    }

}
