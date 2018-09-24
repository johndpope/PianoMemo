//
//  StringCell.swift
//  Piano
//
//  Created by Kevin Kim on 18/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

extension String: CollectionDatable {
    func size(view: View) -> CGSize {
        let safeWidth = view.bounds.width - (view.safeAreaInsets.left + view.safeAreaInsets.right)
        var n = 1
        var usedWidth: CGFloat = 0
        while true {
            let width = CGFloat(50 * n)
            if width > safeWidth { break }
            usedWidth = width
            n += 1
        }
        
        let plusFloat = (safeWidth - usedWidth) / CGFloat(n)
        let plusInt = Int(plusFloat)
        return CGSize(width: 50 + plusInt, height: 50 + plusInt)
    }
}

class StringCell: UICollectionViewCell, CollectionDataAcceptable {
    var data: CollectionDatable? {
        didSet {
            guard let str = data as? String else { return }
            label.text = str
        }
    }
    
    @IBOutlet weak var label: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        selectedBackgroundView = borderView
    }
    
    var borderView: UIView {
        let view = UIView()
        view.backgroundColor = Color(hex6: "B2DAFF")
        view.cornerRadius = 15
        return view
    }
    
    
    
}
