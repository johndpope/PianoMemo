//
//  TagPickerLayout.swift
//  Piano
//
//  Created by hoemoon on 05/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class TagPickerLayout: UICollectionViewFlowLayout {
    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath) else { return nil }


        attributes.isHidden = true
        attributes.zIndex = 10

        return attributes
    }

    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath) else { return nil }

        attributes.alpha = 0
        attributes.isHidden = true

        return attributes
    }
}
