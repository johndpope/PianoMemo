//
//  CollectionRegisterable.swift
//  Piano
//
//  Created by Kevin Kim on 16/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import Foundation

protocol CollectionRegisterable: class {
    var collectionView: CollectionView! { get set }
}

extension CollectionRegisterable {
    func registerCell<T: View>(_ type: T.Type) {
        self.collectionView.register(Nib(nibName: type.reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: type.reuseIdentifier)
    }
    
    func registerHeaderView<T: View>(_ type: T.Type) {
        collectionView.register(Nib(nibName: type.reuseIdentifier, bundle: nil), forSupplementaryViewOfKind: CollectionView.elementKindSectionHeader, withReuseIdentifier: type.reuseIdentifier)
    }
    
    func registerFooterView<T: View>(_ type: T.Type) {
        collectionView.register(Nib(nibName: type.reuseIdentifier, bundle: nil), forSupplementaryViewOfKind: CollectionView.elementKindSectionFooter, withReuseIdentifier: type.reuseIdentifier)
    }
    
}
