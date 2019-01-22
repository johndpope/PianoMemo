//
//  ColumnFlowLayout.swift
//  Piano
//
//  Created by Kevin Kim on 07/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

class NoteColumnFlowLayout: UICollectionViewFlowLayout {

    override func prepare() {
        super.prepare()

        guard let cv = collectionView else { return }
        //width
        let availableWidth = cv.bounds.inset(by: cv.layoutMargins).size.width
        let minColumnWidth = CGFloat(300.0)
        let maxNumColumns = Int(availableWidth / minColumnWidth)
        let cellWidth = (availableWidth / CGFloat(maxNumColumns)).rounded(.down)
        //height
        let margin: CGFloat = 8.0
        let headlineHeight = NSAttributedString(string: "1234567890", attributes: [.font: Font.preferredFont(forTextStyle: .headline)]).size().height
        let subHeadHeight = NSAttributedString(string: "1234567890\n1234567890", attributes: [.font: Font.preferredFont(forTextStyle: .subheadline)]).size().height
        let dateHeight = NSAttributedString(string: "1234567890", attributes: [.font: Font.preferredFont(forTextStyle: .caption1)]).size().height

        let fullHeight: CGFloat = margin * 4 + headlineHeight + subHeadHeight + 22
        self.itemSize = CGSize(width: cellWidth, height: fullHeight)
        self.sectionInset = UIEdgeInsets(top: self.minimumInteritemSpacing, left: 0, bottom: 0, right: 0)
        self.sectionInsetReference = .fromSafeArea
    }

}
