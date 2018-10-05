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
    let isEmoji: Bool
    
    init(string: String, isEmoji: Bool) {
        self.string = string
        self.isEmoji = isEmoji
    }
    
    internal func size(view: View) -> CGSize {
        
        var size = isEmoji
        ? NSAttributedString(string: self.string, attributes: [.font : Font.systemFont(ofSize: 26)]).size()
        : NSAttributedString(string: self.string, attributes: [.font : Font.systemFont(ofSize: 15, weight: .semibold)]).size()
        let leadingMargin = 11
        size.width += CGFloat(leadingMargin * 2)
        size.height = 46
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
            
            label.font = viewModel.isEmoji ? Font.systemFont(ofSize: 26) : Font.systemFont(ofSize: 15, weight: .semibold)
            
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
    
    override var isSelected: Bool {
        didSet {
            label.textColor = isSelected ? .white : Color(red: 69/255, green: 69/255, blue: 69/255, alpha: 1)
        }
    }

}
