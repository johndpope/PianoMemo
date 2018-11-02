//
//  StringCell.swift
//  Piano
//
//  Created by Kevin Kim on 18/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

extension String: Collectionable {
    func size(view: View) -> CGSize {
        let viewWidth = view.bounds.width
        var n = 1
        var usedWidth: CGFloat = 0
        while true {
            let width = CGFloat(50 * n)
            if width > viewWidth { break }
            usedWidth = width
            n += 1
        }
        
        let plusFloat = (viewWidth - usedWidth) / CGFloat(n)
        let plusInt = Int(plusFloat)
        return CGSize(width: 50 + plusInt, height: 50 + plusInt)
    }
}

struct StringViewModel: ViewModel {
    let string: String
    
    init(string: String) {
        self.string = string
    }
}

class StringCell: UICollectionViewCell, ViewModelAcceptable {
    var viewModel: ViewModel? {
        didSet {
            guard let viewModel = viewModel as? StringViewModel else { return }
            label.text = viewModel.string
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
